import asyncio
import aiohttp
from PIL import Image
from io import BytesIO
from auth import supabase
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s:%(message)s',
    handlers=[
        logging.FileHandler("thumbnail_update.log"),
        logging.StreamHandler()
    ]
)

# Constants for pagination
PAGE_SIZE = 50  # Maximum number of records per page


async def fetch_image(session, url):
    """
    Fetches the image from the given URL asynchronously.
    Returns the image bytes if successful, else None.
    """
    try:
        async with session.get(url, timeout=10) as response:
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


async def process_thumbnail(session, thumbnail):
    """
    Processes a single thumbnail: fetches the image, gets dimensions,
    and updates the database.
    """
    thumbnail_id = thumbnail['id']
    url = thumbnail['url']
    logging.info(f"Processing Thumbnail ID: {thumbnail_id}, URL: {url}")

    image_bytes = await fetch_image(session, url)
    if image_bytes is None:
        logging.warning(f"Skipping Thumbnail ID: {thumbnail_id} due to fetch failure.")
        return

    width, height = get_image_dimensions(image_bytes)
    if width is None or height is None:
        logging.warning(f"Skipping Thumbnail ID: {thumbnail_id} due to processing failure.")
        return

    # Update the thumbnail record in Supabase
    try:
        supabase.table('thumbnail').update({
            'width': width,
            'height': height,
        }).eq('id', thumbnail_id).execute()
        logging.info(f"Updated Thumbnail ID: {thumbnail_id} with width: {width}, height: {height}")
    except Exception as e:
        logging.error(f"Error updating Thumbnail ID: {thumbnail_id}: {e}")


async def fetch_thumbnails(offset):
    """
    Fetches a single page of thumbnails where width or height is NULL.
    """
    try:
        response = supabase.table('thumbnail') \
            .select('id, url') \
            .is_('width', None) \
            .is_('height', None) \
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
            semaphore = asyncio.Semaphore(10)

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
