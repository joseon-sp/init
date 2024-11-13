# test_insert_procedure.py

import logging

from auth import supabase  # Ensure auth.py is correctly configured

# Configure logging
logging.basicConfig(
    filename='test_insert_procedure.log',
    filemode='a',
    format='%(asctime)s - %(levelname)s - %(message)s',
    level=logging.DEBUG
)


def test_insert():
    # Sample data for testing
    detail = {
        'uid': 'test_uid_238',
        'name': 'Test Heritage 238',
        'name_hanja': '測試遺產238',
        'city_code': '11',  # Should map to city_id = 1
        'district_code': '11',  # Should map to district_id = 2 (assuming)
        'type_code': '11',  # Ensure this exists in 'heritage_types'
        'canceled': False,
        'last_modified': '2024-11-13',
        'management_number': 'M238',
        'linkage_number': 'L238',
        'longitude': 127.0,
        'latitude': 37.0,
        'type': 'National Treasure',
        'quantity': '1',
        'registered_date': '2024-11-13',
        'location_description': 'Test Location 238',
        'era': 'Modern',
        'owner': 'Test Owner 238',
        'manager': 'Test Manager 238',
        'thumbnail': 'http://example.com/thumbnail238.jpg',
        'content': 'Test Content 238'
    }

    images = [
        {
            'licence': 'License1',
            'image_url': 'http://example.com/image1.jpg',
            'description': 'Image 1 Description'
        },
        {
            'licence': 'License2',
            'image_url': 'http://example.com/image2.jpg',
            'description': 'Image 2 Description'
        }
    ]

    videos = [
        {'video_url': 'http://example.com/video1.mp4'},
        {'video_url': 'http://example.com/video2.mp4'}
    ]

    # Extract category names
    category_names = {
        'p_category1_name': 'Historical',
        'p_category2_name': 'Cultural',
        'p_category3_name': 'Artistic',
        'p_category4_name': 'Architectural'
    }

    try:
        # Log the parameters
        logging.debug(
            f"Calling stored procedure with p_city_code: '{detail['city_code']}' and p_district_code: '{detail['district_code']}'")

        # Call the stored procedure
        response = supabase.rpc(
            'insert_heritage_item_with_relations',
            {
                'p_uid': detail['uid'],
                'p_name': detail['name'],
                'p_name_hanja': detail['name_hanja'],
                'p_city_code': detail['city_code'],  # '11'
                'p_district_code': detail['district_code'],  # '11'
                'p_heritage_type_code': detail['type_code'],
                'p_canceled': detail['canceled'],
                'p_last_modified': detail['last_modified'],
                'p_management_number': detail['management_number'],
                'p_linkage_number': detail['linkage_number'],
                'p_longitude': detail['longitude'],
                'p_latitude': detail['latitude'],
                'p_type': detail['type'],
                'p_quantity': detail['quantity'],
                'p_registered_date': detail['registered_date'],
                'p_location_description': detail['location_description'],
                'p_era': detail['era'],
                'p_owner': detail['owner'],
                'p_manager': detail['manager'],
                'p_thumbnail': detail['thumbnail'],
                'p_content': detail['content'],
                'p_category1_name': category_names['p_category1_name'],
                'p_category2_name': category_names['p_category2_name'],
                'p_category3_name': category_names['p_category3_name'],
                'p_category4_name': category_names['p_category4_name'],
                'p_images': images if images else None,
                'p_videos': videos if videos else None
            }
        ).execute()

        if response.status_code == 200:
            logging.info("Successfully inserted heritage_item.")
        else:
            logging.error(f"Failed to insert heritage_item: {response.json()}")

    except Exception as e:
        logging.error(f"Exception occurred during insertion: {e}")


if __name__ == "__main__":
    test_insert()
