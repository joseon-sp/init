import asyncio
import logging
import os
from io import BytesIO

import aiohttp
from PIL import Image

from auth import supabase, BASE_URL

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s:%(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)

# Constants for pagination
PAGE_SIZE = 50  # Maximum number of records per page
STORAGE_BUCKET = os.getenv("SUPABASE_STORAGE_BUCKET")  # Ensure this is set in your .env file

# Ensure the temp directory exists
TEMP_DIR = "./temp"
os.makedirs(TEMP_DIR, exist_ok=True)


async def fetch_image(session, url):
    """
    Fetches the image from the given URL asynchronously.
    Returns the image bytes if successful, else None.
    """
    try:
        async with session.get(url, timeout=20) as response:
            if response.status == 200:
                return await response.read()
            else:
                logging.warning(f"Failed to fetch {url}: Status {response.status}")
                return None
    except Exception as e:
        logging.error(f"Error fetching {url}: {e}")
        return None


def get_image_dimensions(image_bytes):
    """
    Returns the width and height of the image.
    """
    try:
        with Image.open(BytesIO(image_bytes)) as img:
            return img.width, img.height
    except Exception as e:
        logging.error(f"Error processing image: {e}")
        return None, None


def resize_image(image_bytes, max_width=640):
    """
    Resizes the image to the specified max width while maintaining aspect ratio.
    Returns the resized image bytes in WebP format.
    """
    try:
        with Image.open(BytesIO(image_bytes)) as img:
            # Calculate the new height to maintain aspect ratio
            if img.width > max_width:
                ratio = max_width / float(img.width)
                new_height = int(float(img.height) * ratio)
                img = img.resize((max_width, new_height), Image.Resampling.LANCZOS)
                logging.info(f"Resized image to ({max_width}, {new_height})")
            else:
                logging.info(
                    f"Image width ({img.width}) is less than or equal to max width ({max_width}). Skipping resize.")

            # Convert image to WebP format
            resized_io = BytesIO()
            img.save(resized_io, format="WEBP", quality=80, optimize=True)
            resized_bytes = resized_io.getvalue()
            return resized_bytes
    except Exception as e:
        logging.error(f"Error resizing image: {e}")
        return None


async def upload_optimized_image(thumbnail_id, optimized_filename, optimized_bytes):
    """
    Uploads the optimized image to Supabase Storage using the provided upload setup.
    Returns the public URL if successful, else None.
    """
    optimized_filepath = os.path.join(TEMP_DIR, optimized_filename)
    try:
        # Save the optimized image to a temporary file
        with open(optimized_filepath, 'wb') as f:
            f.write(optimized_bytes)
        logging.info(f"Saved optimized image to {optimized_filepath}")
    except Exception as e:
        logging.error(f"Error saving optimized image for Thumbnail ID {thumbnail_id}: {e}")
        return None

    # Upload the image using the provided upload setup
    try:
        with open(optimized_filepath, 'rb') as f:
            response = supabase.storage.from_("thumbnail").upload(
                file=f,
                path=optimized_filename,
                file_options={"upsert": "True", "content-type": "image/webp"}, )

        # Handle the response based on the client version
        if isinstance(response, dict) and 'Key' in response:
            # Use get_public_url to retrieve the public URL
            public_url_response = supabase.storage.from_("thumbnail").get_public_url(optimized_filename)
            optimized_url = public_url_response.public_url
            logging.info(f"Uploaded optimized image for Thumbnail ID {thumbnail_id} to {optimized_url}")
            return optimized_url
        else:
            # If response is not a dict with 'Key', handle it as a bool
            if response:
                optimized_url = f"{BASE_URL}/storage/v1/object/public/thumbnail/{optimized_filename}"
                logging.info(f"Uploaded optimized image for Thumbnail ID {thumbnail_id} to {optimized_url}")
                return optimized_url
            else:
                logging.error(f"Upload failed for Thumbnail ID {thumbnail_id}: Received False")
                return None
    except Exception as e:
        logging.error(f"Failed to upload image for Thumbnail ID {thumbnail_id}: {e}")
        return None
    finally:
        # Clean up the temporary file
        try:
            os.remove(optimized_filepath)
            logging.info(f"Deleted temporary file {optimized_filepath}")
        except Exception as e:
            logging.error(f"Error deleting temporary file {optimized_filepath}: {e}")


async def process_thumbnail(session, thumbnail):
    """
    Processes a single thumbnail:
    - Fetches the original image.
    - Resizes it to a max width of 640px.
    - Uploads the optimized image to Supabase Storage.
    - Updates the database with the optimized image URL and its dimensions.
    """
    thumbnail_id = thumbnail['id']
    url = thumbnail['url']
    logging.info(f"Processing Thumbnail ID: {thumbnail_id}, URL: {url}")

    # Fetch original image
    image_bytes = await fetch_image(session, url)
    if image_bytes is None:
        logging.warning(f"Skipping Thumbnail ID: {thumbnail_id} due to fetch failure.")
        return

    # Get dimensions of original image
    original_width, original_height = get_image_dimensions(image_bytes)
    if original_width is None or original_height is None:
        logging.warning(f"Skipping Thumbnail ID: {thumbnail_id} due to image processing failure.")
        return

    # Resize the image
    resized_bytes = resize_image(image_bytes, max_width=640)
    if resized_bytes is None:
        logging.warning(f"Skipping Thumbnail ID: {thumbnail_id} due to resizing failure.")
        return

    # Determine optimized image filename
    optimized_filename = f"{thumbnail_id}.webp"

    # Upload the optimized image and get its URL
    optimized_url = await upload_optimized_image(thumbnail_id, optimized_filename, resized_bytes)
    if optimized_url is None:
        logging.warning(f"Skipping Thumbnail ID: {thumbnail_id} due to upload failure.")
        return

    # Get dimensions of optimized image
    optimized_width, optimized_height = get_image_dimensions(resized_bytes)
    if optimized_width is None or optimized_height is None:
        logging.warning(f"Skipping Thumbnail ID: {thumbnail_id} due to optimized image processing failure.")
        return

    # Update the thumbnail record in Supabase
    try:
        supabase.table('thumbnail').update({
            'optimized_url': optimized_url,
            'optimized_width': optimized_width,
            'optimized_height': optimized_height,
        }).eq('id', thumbnail_id).execute()
        logging.info(f"Updated Thumbnail ID: {thumbnail_id} with optimized image details.")
    except Exception as e:
        logging.error(f"Error updating Thumbnail ID: {thumbnail_id}: {e}")


async def fetch_thumbnails(offset):
    """
    Fetches a single page of thumbnails where optimized_url is NULL.
    """
    try:
        response = supabase.table('thumbnail') \
            .select('id, url') \
            .is_('optimized_url', None) \
            .range(offset, offset + PAGE_SIZE - 1) \
            .execute()

        return response.data  # Returns a list of thumbnails
    except Exception as e:
        logging.error(f"Error fetching thumbnails for offset {offset}: {e}")
        return []


async def main():
    """
    Main asynchronous function to process all thumbnails with pagination.
    """
    offset = 0
    total_processed = 0

    # Use a session for all HTTP requests
    async with aiohttp.ClientSession() as session:
        while True:
            thumbnails = await fetch_thumbnails(offset)
            if not thumbnails:
                if offset == 0:
                    logging.info("No thumbnails to process. Exiting.")
                else:
                    logging.info(f"All thumbnails processed up to offset {offset - PAGE_SIZE}. Exiting.")
                break

            logging.info(f"Processing Thumbnails with offset {offset}: {len(thumbnails)} thumbnails.")

            # Create a list of tasks for concurrent processing
            tasks = [process_thumbnail(session, thumbnail) for thumbnail in thumbnails]

            # Limit the number of concurrent tasks to avoid overwhelming the server
            semaphore = asyncio.Semaphore(30)

            async def sem_task(task):
                async with semaphore:
                    await task

            # Wrap tasks with semaphore
            sem_tasks = [sem_task(task) for task in tasks]

            # Run all tasks concurrently
            await asyncio.gather(*sem_tasks)

            total_processed += len(thumbnails)
            logging.info(f"Completed processing offset {offset}. Total thumbnails processed: {total_processed}")

            offset += PAGE_SIZE  # Move to the next page

    logging.info("Thumbnail processing completed.")


if __name__ == "__main__":
    asyncio.run(main())
