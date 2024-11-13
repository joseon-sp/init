-- ===================================================
-- 2. Updated Stored Procedure to Handle Nullable Categories
-- ===================================================

CREATE OR REPLACE FUNCTION public.insert_heritage_item_with_relations(
    p_uid VARCHAR,
    p_name VARCHAR,
    p_name_hanja VARCHAR,
    p_city_code VARCHAR,
    p_district_code VARCHAR,
    p_heritage_type_code VARCHAR,
    p_canceled BOOLEAN,
    p_last_modified DATE,
    p_management_number VARCHAR,
    p_linkage_number VARCHAR,
    p_longitude DOUBLE PRECISION,
    p_latitude DOUBLE PRECISION,
    p_type VARCHAR,
    p_quantity VARCHAR,
    p_registered_date DATE,
    p_location_description TEXT,
    p_era VARCHAR,
    p_owner VARCHAR,
    p_manager VARCHAR,
    p_thumbnail TEXT,
    p_content TEXT,
    p_category1_name VARCHAR,
    p_category2_name VARCHAR,
    p_category3_name VARCHAR,
    p_category4_name VARCHAR,
    p_images JSONB,  -- Array of JSON objects with 'licence', 'image_url', 'description'
    p_videos JSONB   -- Array of video URLs
)
RETURNS VOID
LANGUAGE plpgsql
SET search_path = public, pg_catalog  -- Explicitly set search_path here
AS $$
DECLARE
    v_city_id INTEGER;
    v_district_id INTEGER;
    v_heritage_type_id INTEGER;
    v_heritage_item_id UUID;
    v_category1_id INTEGER;
    v_category2_id INTEGER;
    v_category3_id INTEGER;
    v_category4_id INTEGER;
BEGIN
    -- Removed SET search_path = public; from here

    -- Start Transaction
    BEGIN
        -- Resolve Foreign Keys

        -- Attempt to retrieve city_id; set to NULL if not found
        SELECT id INTO v_city_id FROM public.cities WHERE code = p_city_code;
        IF v_city_id IS NULL THEN
            RAISE NOTICE 'City code % not found. Setting city_id to NULL.', p_city_code;
        ELSE
            RAISE NOTICE 'Resolved city_id: % for city_code: %', v_city_id, p_city_code;
        END IF;

        -- Attempt to retrieve district_id; set to NULL if not found
        IF v_city_id IS NOT NULL THEN
            SELECT id INTO v_district_id FROM public.districts WHERE city_id = v_city_id AND code = p_district_code;
            IF v_district_id IS NULL THEN
                RAISE NOTICE 'District code % not found for city_id %. Setting district_id to NULL.', p_district_code, v_city_id;
            ELSE
                RAISE NOTICE 'Resolved district_id: % for district_code: % and city_id: %', v_district_id, p_district_code, v_city_id;
            END IF;
        ELSE
            RAISE NOTICE 'City_id is NULL. Setting district_id to NULL.';
            v_district_id := NULL;
        END IF;

        -- Attempt to retrieve heritage_type_id; set to NULL if not found
        SELECT id INTO v_heritage_type_id FROM public.heritage_types WHERE code = p_heritage_type_code;
        IF v_heritage_type_id IS NULL THEN
            RAISE NOTICE 'Heritage type code % not found. Setting heritage_type_id to NULL.', p_heritage_type_code;
        ELSE
            RAISE NOTICE 'Resolved heritage_type_id: % for heritage_type_code: %', v_heritage_type_id, p_heritage_type_code;
        END IF;

        -- Handle Category1
        IF p_category1_name IS NOT NULL AND p_category1_name <> '' THEN
            SELECT id INTO v_category1_id FROM public.categories WHERE name = p_category1_name AND level = 1;
            IF v_category1_id IS NULL THEN
                INSERT INTO public.categories (name, parent_id, level) VALUES (p_category1_name, NULL, 1)
                RETURNING id INTO v_category1_id;
                RAISE NOTICE 'Inserted new category1_id: %', v_category1_id;
            ELSE
                RAISE NOTICE 'Found existing category1_id: %', v_category1_id;
            END IF;
        ELSE
            RAISE NOTICE 'Category1 name is NULL or empty. Setting category1_id to NULL.';
            v_category1_id := NULL;
        END IF;

        -- Handle Category2
        IF p_category2_name IS NOT NULL AND p_category2_name <> '' AND v_category1_id IS NOT NULL THEN
            SELECT id INTO v_category2_id FROM public.categories WHERE name = p_category2_name AND parent_id = v_category1_id AND level = 2;
            IF v_category2_id IS NULL THEN
                INSERT INTO public.categories (name, parent_id, level) VALUES (p_category2_name, v_category1_id, 2)
                RETURNING id INTO v_category2_id;
                RAISE NOTICE 'Inserted new category2_id: %', v_category2_id;
            ELSE
                RAISE NOTICE 'Found existing category2_id: %', v_category2_id;
            END IF;
        ELSE
            RAISE NOTICE 'Category2 name is NULL or empty, or parent category1_id is NULL. Setting category2_id to NULL.';
            v_category2_id := NULL;
        END IF;

        -- Handle Category3
        IF p_category3_name IS NOT NULL AND p_category3_name <> '' AND v_category2_id IS NOT NULL THEN
            SELECT id INTO v_category3_id FROM public.categories WHERE name = p_category3_name AND parent_id = v_category2_id AND level = 3;
            IF v_category3_id IS NULL THEN
                INSERT INTO public.categories (name, parent_id, level) VALUES (p_category3_name, v_category2_id, 3)
                RETURNING id INTO v_category3_id;
                RAISE NOTICE 'Inserted new category3_id: %', v_category3_id;
            ELSE
                RAISE NOTICE 'Found existing category3_id: %', v_category3_id;
            END IF;
        ELSE
            RAISE NOTICE 'Category3 name is NULL or empty, or parent category2_id is NULL. Setting category3_id to NULL.';
            v_category3_id := NULL;
        END IF;

        -- Handle Category4
        IF p_category4_name IS NOT NULL AND p_category4_name <> '' AND v_category3_id IS NOT NULL THEN
            SELECT id INTO v_category4_id FROM public.categories WHERE name = p_category4_name AND parent_id = v_category3_id AND level = 4;
            IF v_category4_id IS NULL THEN
                INSERT INTO public.categories (name, parent_id, level) VALUES (p_category4_name, v_category3_id, 4)
                RETURNING id INTO v_category4_id;
                RAISE NOTICE 'Inserted new category4_id: %', v_category4_id;
            ELSE
                RAISE NOTICE 'Found existing category4_id: %', v_category4_id;
            END IF;
        ELSE
            RAISE NOTICE 'Category4 name is NULL or empty, or parent category3_id is NULL. Setting category4_id to NULL.';
            v_category4_id := NULL;
        END IF;

        -- Handle longitude and latitude: set to NULL if 0
        IF p_longitude = 0 THEN
            p_longitude := NULL;
            RAISE NOTICE 'Longitude is 0. Setting to NULL.';
        END IF;

        IF p_latitude = 0 THEN
            p_latitude := NULL;
            RAISE NOTICE 'Latitude is 0. Setting to NULL.';
        END IF;

        -- Insert into heritage_items
        INSERT INTO public.heritage_items (
            uid, name, name_hanja, city_id, district_id, heritage_type_id,
            canceled, last_modified, management_number, linkage_number,
            longitude, latitude, type, quantity, registered_date,
            location_description, era, owner, manager, thumbnail, content,
            category1_id, category2_id, category3_id, category4_id
        ) VALUES (
            p_uid, p_name, p_name_hanja, v_city_id, v_district_id, v_heritage_type_id,
            p_canceled, p_last_modified, p_management_number, p_linkage_number,
            p_longitude, p_latitude, p_type, p_quantity, p_registered_date,
            p_location_description, p_era, p_owner, p_manager, p_thumbnail, p_content,
            v_category1_id, v_category2_id, v_category3_id, v_category4_id
        )
        RETURNING id INTO v_heritage_item_id;
        RAISE NOTICE 'Inserted heritage_item_id: % for uid: %', v_heritage_item_id, p_uid;

        -- Insert Images
        IF p_images IS NOT NULL THEN
            INSERT INTO public.images (heritage_item_id, image_license, image_url, description)
            SELECT
                v_heritage_item_id,
                img->>'licence',
                img->>'image_url',
                img->>'description'
            FROM jsonb_array_elements(p_images) AS img
            WHERE (img->>'image_url') IS NOT NULL AND (img->>'image_url') <> '';
            RAISE NOTICE 'Inserted images for heritage_item_id: %', v_heritage_item_id;
        END IF;

        -- Insert Videos
        IF p_videos IS NOT NULL THEN
            INSERT INTO public.videos (heritage_item_id, video_url)
            SELECT
                v_heritage_item_id,
                vid->>'video_url'
            FROM jsonb_array_elements(p_videos) AS vid
            WHERE (vid->>'video_url') IS NOT NULL AND (vid->>'video_url') <> '';
            RAISE NOTICE 'Inserted videos for heritage_item_id: %', v_heritage_item_id;
        END IF;

    EXCEPTION WHEN OTHERS THEN
        -- If any error occurs, propagate the error
        RAISE;
    END;
END;
$$;
