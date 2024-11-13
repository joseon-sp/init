import logging
import sys
import time
from typing import Optional

from supabase import Client

from auth import supabase  # Ensure auth.py is in the same directory
from kheritageapi.heritage import HeritageSearcher, HeritageInfo
from kheritageapi.models import HeritagSearchResultItem, HeritageDetail, HeritageVideoSet, HeritageImageSet

# Configure main logger
logger = logging.getLogger('main_logger')
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')

# Console handler for main logger
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

# File handler for main logger
file_handler = logging.FileHandler("app.log")
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

# Configure invalid data logger
invalid_logger = logging.getLogger('invalid_data_logger')
invalid_logger.setLevel(logging.WARNING)
invalid_file_handler = logging.FileHandler("invalid_data.log")
invalid_file_handler.setFormatter(formatter)
invalid_logger.addHandler(invalid_file_handler)

# Constants
RESULT_COUNT = 100  # Number of items per page; adjust based on API capabilities
MAX_RETRIES = 5  # Max retries for API requests


def heritage_item_exists(uid: str, supabase_client: Client) -> bool:
    """Check if a heritage item with the given UID already exists in the database."""
    try:
        response = supabase_client.table('heritage_items').select('id').eq('uid', uid).execute()
        exists = len(response.data) > 0
        logger.debug(f"Heritage item with uid {uid} exists: {exists}")
        return exists
    except Exception as e:
        logger.error(f"Error checking existence of heritage_item with uid {uid}: {e}")
        return False  # Assume it doesn't exist to prevent skipping


def extract_district_code(detail: HeritageDetail) -> Optional[str]:
    """
    Extract district_code from linkage_number or another available field.
    Adjust this logic based on your actual data structure.
    For example, assuming the first two characters of linkage_number represent district_code.
    """
    if detail.linkage_number and len(detail.linkage_number) >= 2:
        return detail.linkage_number[:2].strip()
    else:
        # Alternative extraction logic if needed
        return None


def extract_category_names(detail: HeritageDetail) -> dict:
    """Extract category names from HeritageDetail."""
    return {
        'p_category1_name': detail.category1.strip() if detail.category1 else None,
        'p_category2_name': detail.category2.strip() if detail.category2 else None,
        'p_category3_name': detail.category3.strip() if detail.category3 else None,
        'p_category4_name': detail.category4.strip() if detail.category4 else None
    }


def call_insert_stored_procedure(detail: HeritageDetail, images: HeritageImageSet, videos: HeritageVideoSet,
                                 supabase_client: Client) -> bool:
    """Call the stored procedure to insert heritage item with images and videos."""
    try:
        # Prepare images data
        images_data = [
            {
                'licence': img.licence,
                'image_url': img.image_url,
                'description': img.description
            }
            for img in images
            if img.image_url and img.image_url.strip() != ''
        ]

        # Prepare videos data
        videos_data = [
            {'video_url': vid}
            for vid in videos
            if vid.strip() != ''
        ]

        # Extract district_code
        district_code = extract_district_code(detail)
        if not district_code:
            logger.warning(
                f"District code could not be extracted for heritage_item with uid {detail.uid}. Setting to NULL.")
        else:
            district_code = district_code.strip()
            logger.debug(f"Extracted district_code: '{district_code}' for uid {detail.uid}")

        # Extract category names
        category_names = extract_category_names(detail)
        if not any(category_names.values()):
            logger.warning(
                f"All category names are missing or empty for heritage_item with uid {detail.uid}. Setting categories to NULL.")
            category_names = {k: None for k in category_names}  # Set all to None
        else:
            # Set any missing category names to None
            for key, value in category_names.items():
                if not value:
                    category_names[key] = None
            logger.debug(f"Category names: {category_names} for uid {detail.uid}")

        # Handle longitude and latitude: set to None if 0
        longitude = float(detail.longitude) if detail.longitude and float(detail.longitude) != 0 else None
        if longitude is None:
            logger.debug(f"Longitude is 0 or missing for uid {detail.uid}. Setting to NULL.")
        latitude = float(detail.latitude) if detail.latitude and float(detail.latitude) != 0 else None
        if latitude is None:
            logger.debug(f"Latitude is 0 or missing for uid {detail.uid}. Setting to NULL.")

        # Convert dates to the correct format
        def format_date(date_value):
            if date_value and isinstance(date_value, (time.struct_time, tuple, list)):
                return time.strftime('%Y-%m-%d', date_value)
            elif isinstance(date_value, str):
                return date_value  # Assume it's already in the correct format
            return None

        last_modified_date = format_date(detail.last_modified)
        if last_modified_date:
            logger.debug(f"Formatted last_modified_date: '{last_modified_date}'")
        registered_date = format_date(detail.registered_date)
        if registered_date:
            logger.debug(f"Formatted registered_date: '{registered_date}'")

        # Call the stored procedure
        supabase_client.rpc(
            'insert_heritage_item_with_relations',
            {
                'p_uid': detail.uid,
                'p_name': detail.name,
                'p_name_hanja': detail.name_hanja,
                'p_city_code': detail.city_code if detail.city_code else None,  # Ensure it's a string or None
                'p_district_code': district_code if district_code else None,
                'p_heritage_type_code': detail.type_code,
                'p_canceled': detail.canceled,
                'p_last_modified': last_modified_date,
                'p_management_number': detail.management_number,
                'p_linkage_number': detail.linkage_number,
                'p_longitude': longitude,
                'p_latitude': latitude,
                'p_type': detail.type,
                'p_quantity': detail.quantity,
                'p_registered_date': registered_date,
                'p_location_description': detail.location_description,
                'p_era': detail.era,
                'p_owner': detail.owner,
                'p_manager': detail.manager,
                'p_thumbnail': detail.thumbnail,
                'p_content': detail.content,
                'p_category1_name': category_names['p_category1_name'],
                'p_category2_name': category_names['p_category2_name'],
                'p_category3_name': category_names['p_category3_name'],
                'p_category4_name': category_names['p_category4_name'],
                'p_images': images_data if images_data else None,
                'p_videos': videos_data if videos_data else None
            }
        ).execute()

        logger.info(f"Successfully inserted heritage_item with uid {detail.uid}")
        return True

    except Exception as e:
        logger.error(f"Error inserting heritage_item with uid {detail.uid}: {e}")
        # Log invalid data to invalid_data.log
        invalid_logger.warning(f"Invalid data for heritage_item with uid {detail.uid}: {detail.__dict__}")
        return False


def main():
    page_index = 1
    total_pages = None

    while True:
        logger.info(f"Starting page {page_index}")

        # Initialize HeritageSearcher
        search = HeritageSearcher(result_count=RESULT_COUNT, page_index=page_index)
        retries = 0
        success = False
        while retries < MAX_RETRIES and not success:
            try:
                results: HeritagSearchResultItem = search.perform_search()
                success = True
            except Exception as e:
                retries += 1
                logger.error(f"Error fetching page {page_index}: {e}. Retry {retries}/{MAX_RETRIES}")
                time.sleep(2 ** retries)  # Exponential backoff

        if not success:
            logger.critical(f"Failed to fetch page {page_index} after {MAX_RETRIES} retries. Exiting.")
            sys.exit(1)

        if total_pages is None:
            try:
                total_items = int(results.hits)  # Convert to integer
            except ValueError:
                logger.error(f"Invalid total_items value: {results.hits}. It must be an integer.")
                # Log invalid data to invalid_data.log
                invalid_logger.warning(f"Invalid total_items value: {results.hits}")
                sys.exit(1)

            total_pages = (total_items // RESULT_COUNT) + (1 if total_items % RESULT_COUNT > 0 else 0)
            logger.info(f"Total items: {total_items}, Total pages: {total_pages}")

        if not results.items:
            logger.info(f"No items found on page {page_index}. Ending pagination.")
            break

        for result in results.items:
            try:
                uid = result.uid
                if heritage_item_exists(uid, supabase):
                    logger.info(f"Heritage item with uid {uid} already exists. Skipping.")
                    continue

                # Retrieve detailed information
                item = HeritageInfo(result)
                detail: HeritageDetail = item.retrieve_detail()
                images: HeritageImageSet = item.retrieve_image()
                videos: HeritageVideoSet = item.retrieve_video()

                # Insert into the database using the stored procedure
                insertion_success = call_insert_stored_procedure(detail, images, videos, supabase)
                if not insertion_success:
                    # Log the failure and continue with the next item
                    logger.warning(
                        f"Insertion failed for heritage_item with uid {uid}. Logged invalid data and continuing.")
                    continue  # Continue with the next item instead of exiting

            except Exception as e:
                logger.exception(f"Exception occurred while processing heritage_item with uid {result.uid}: {e}")
                # Log invalid data to invalid_data.log
                invalid_logger.warning(
                    f"Exception data for uid {result.uid}: {result.__dict__ if hasattr(result, '__dict__') else str(result)}")
                # Continue with the next item instead of exiting
                continue

        logger.info(f"Completed page {page_index}")
        page_index += 1

        if page_index > total_pages:
            logger.info("All pages processed.")
            break

    logger.info("Database population completed successfully.")


if __name__ == "__main__":
    main()
