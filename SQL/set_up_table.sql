-- ===================================================
-- 1. Enable Necessary Extensions
-- ===================================================

-- Enable the pgcrypto extension for UUID generation
CREATE
EXTENSION IF NOT EXISTS pgcrypto;

-- Create a dedicated schema for extensions
CREATE SCHEMA IF NOT EXISTS extensions;

-- Enable the PostGIS extension within the 'extensions' schema
CREATE
EXTENSION IF NOT EXISTS postgis SCHEMA extensions;

-- ===================================================
-- 2. Create the 'cities' Table with Integer Primary Keys
-- ===================================================

CREATE TABLE public.cities
(
    id   SERIAL PRIMARY KEY,           -- Auto-incremented integer ID
    code VARCHAR(2)   NOT NULL UNIQUE, -- e.g., '11', '21', etc.
    name VARCHAR(255) NOT NULL UNIQUE  -- e.g., '서울', '부산', etc.
);

-- ===================================================
-- 3. Populate the 'cities' Table
-- ===================================================

INSERT INTO public.cities (code, name)
VALUES ('11', '서울'),
       ('21', '부산'),
       ('22', '대구'),
       ('23', '인천'),
       ('24', '광주'),
       ('25', '대전'),
       ('26', '울산'),
       ('45', '세종'),
       ('31', '경기'),
       ('32', '강원'),
       ('33', '충북'),
       ('34', '충남'),
       ('35', '전북'),
       ('36', '전남'),
       ('37', '경북'),
       ('38', '경남'),
       ('50', '제주'),
       ('ZZ', '전국일원');

-- ===================================================
-- 4. Create the 'districts' Table with Integer Primary Keys
-- ===================================================

CREATE TABLE public.districts
(
    id      SERIAL PRIMARY KEY,    -- Auto-incremented integer ID
    city_id INTEGER      NOT NULL REFERENCES public.cities (id),
    code    VARCHAR(2)   NOT NULL, -- e.g., '11', '12', etc.
    name    VARCHAR(255) NOT NULL, -- e.g., '종로구', '중구', etc.
    UNIQUE (city_id, code)         -- Ensure uniqueness within a city
);

-- ===================================================
-- 5. Populate the 'districts' Table
-- ===================================================

-- Helper Function to Retrieve City ID
-- This ensures that the city IDs are correctly mapped based on their codes
CREATE
OR REPLACE FUNCTION get_city_id(city_code VARCHAR(2)) RETURNS INTEGER AS $$
BEGIN
RETURN (SELECT id
        FROM public.cities
        WHERE code = city_code);
END;
$$
LANGUAGE plpgsql;

-- Insert districts for 서울 (Seoul)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('11'), '00', '전체'),
       (get_city_id('11'), '11', '종로구'),
       (get_city_id('11'), '12', '중구'),
       (get_city_id('11'), '13', '용산구'),
       (get_city_id('11'), '14', '성동구'),
       (get_city_id('11'), '15', '동대문구'),
       (get_city_id('11'), '16', '성북구'),
       (get_city_id('11'), '17', '도봉구'),
       (get_city_id('11'), '18', '은평구'),
       (get_city_id('11'), '19', '서대문구'),
       (get_city_id('11'), '20', '마포구'),
       (get_city_id('11'), '21', '강서구'),
       (get_city_id('11'), '22', '구로구'),
       (get_city_id('11'), '23', '영등포구'),
       (get_city_id('11'), '24', '동작구'),
       (get_city_id('11'), '25', '관악구'),
       (get_city_id('11'), '26', '강남구'),
       (get_city_id('11'), '27', '강동구'),
       (get_city_id('11'), '28', '송파구'),
       (get_city_id('11'), '29', '중랑구'),
       (get_city_id('11'), '30', '노원구'),
       (get_city_id('11'), '31', '서초구'),
       (get_city_id('11'), '32', '양천구'),
       (get_city_id('11'), '33', '광진구'),
       (get_city_id('11'), '34', '강북구'),
       (get_city_id('11'), '35', '금천구'),
       (get_city_id('11'), '99', '한강일원'),
       (get_city_id('11'), 'ZZ', '서울전역');

-- Insert districts for 부산 (Busan)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('21'), '00', '전체'),
       (get_city_id('21'), '11', '중구'),
       (get_city_id('21'), '12', '서구'),
       (get_city_id('21'), '13', '동구'),
       (get_city_id('21'), '14', '영도구'),
       (get_city_id('21'), '15', '부산진구'),
       (get_city_id('21'), '16', '동래구'),
       (get_city_id('21'), '17', '남구'),
       (get_city_id('21'), '18', '북구'),
       (get_city_id('21'), '19', '해운대구'),
       (get_city_id('21'), '20', '사하구'),
       (get_city_id('21'), '21', '금정구'),
       (get_city_id('21'), '22', '강서구'),
       (get_city_id('21'), '23', '연제구'),
       (get_city_id('21'), '24', '수영구'),
       (get_city_id('21'), '25', '사상구'),
       (get_city_id('21'), '26', '기장군'),
       (get_city_id('21'), 'ZZ', '부산전역');

-- Insert districts for 대구 (Daegu)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('22'), '00', '전체'),
       (get_city_id('22'), '11', '중구'),
       (get_city_id('22'), '12', '동구'),
       (get_city_id('22'), '13', '서구'),
       (get_city_id('22'), '14', '남구'),
       (get_city_id('22'), '15', '북구'),
       (get_city_id('22'), '16', '수성구'),
       (get_city_id('22'), '17', '달서구'),
       (get_city_id('22'), '18', '달성군'),
       (get_city_id('22'), '32', '군위군'),
       (get_city_id('22'), 'ZZ', '대구전역');

-- Insert districts for 인천 (Incheon)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('23'), '00', '전체'),
       (get_city_id('23'), '11', '중구'),
       (get_city_id('23'), '12', '동구'),
       (get_city_id('23'), '15', '서구'),
       (get_city_id('23'), '16', '남동구'),
       (get_city_id('23'), '17', '연수구'),
       (get_city_id('23'), '18', '부평구'),
       (get_city_id('23'), '19', '계양구'),
       (get_city_id('23'), '20', '미추홀구'),
       (get_city_id('23'), '30', '강화군'),
       (get_city_id('23'), '31', '옹진군'),
       (get_city_id('23'), 'ZZ', '인천전역');

-- Insert districts for 광주 (Gwangju)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('24'), '00', '전체'),
       (get_city_id('24'), '11', '동구'),
       (get_city_id('24'), '12', '서구'),
       (get_city_id('24'), '13', '북구'),
       (get_city_id('24'), '14', '광산구'),
       (get_city_id('24'), '15', '남구'),
       (get_city_id('24'), 'ZZ', '광주전역');

-- Insert districts for 대전 (Daejeon)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('25'), '00', '전체'),
       (get_city_id('25'), '11', '동구'),
       (get_city_id('25'), '12', '중구'),
       (get_city_id('25'), '13', '서구'),
       (get_city_id('25'), '14', '유성구'),
       (get_city_id('25'), '15', '대덕구'),
       (get_city_id('25'), 'ZZ', '대전전역');

-- Insert districts for 울산 (Ulsan)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('26'), '00', '전체'),
       (get_city_id('26'), '01', '남구'),
       (get_city_id('26'), '02', '동구'),
       (get_city_id('26'), '03', '북구'),
       (get_city_id('26'), '04', '중구'),
       (get_city_id('26'), '05', '울주군'),
       (get_city_id('26'), 'ZZ', '울산전역');

-- Insert districts for 세종 (Sejong)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('45'), '00', '세종시전역');

-- Insert districts for 경기 (Gyeonggi)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('31'), '00', '전체'),
       (get_city_id('31'), '11', '수원시'),
       (get_city_id('31'), '12', '성남시'),
       (get_city_id('31'), '13', '의정부시'),
       (get_city_id('31'), '14', '안양시'),
       (get_city_id('31'), '15', '부천시'),
       (get_city_id('31'), '16', '광명시'),
       (get_city_id('31'), '17', '안성시'),
       (get_city_id('31'), '18', '동두천시'),
       (get_city_id('31'), '19', '구리시'),
       (get_city_id('31'), '20', '평택시'),
       (get_city_id('31'), '21', '과천시'),
       (get_city_id('31'), '22', '안산시'),
       (get_city_id('31'), '25', '오산시'),
       (get_city_id('31'), '26', '의왕시'),
       (get_city_id('31'), '27', '군포시'),
       (get_city_id('31'), '28', '시흥시'),
       (get_city_id('31'), '30', '하남시'),
       (get_city_id('31'), '31', '양주시'),
       (get_city_id('31'), '70', '여주시'),
       (get_city_id('31'), '35', '화성시'),
       (get_city_id('31'), '37', '파주시'),
       (get_city_id('31'), '39', '광주시'),
       (get_city_id('31'), '40', '연천군'),
       (get_city_id('31'), '41', '포천시'),
       (get_city_id('31'), '42', '가평군'),
       (get_city_id('31'), '43', '양평군'),
       (get_city_id('31'), '44', '이천시'),
       (get_city_id('31'), '45', '용인시'),
       (get_city_id('31'), '47', '김포시'),
       (get_city_id('31'), '50', '고양시'),
       (get_city_id('31'), '51', '남양주시'),
       (get_city_id('31'), 'ZZ', '경기전역');

-- Insert districts for 강원 (Gangwon)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('32'), '00', '전체'),
       (get_city_id('32'), '11', '춘천시'),
       (get_city_id('32'), '12', '원주시'),
       (get_city_id('32'), '13', '강릉시'),
       (get_city_id('32'), '14', '동해시'),
       (get_city_id('32'), '15', '태백시'),
       (get_city_id('32'), '16', '속초시'),
       (get_city_id('32'), '17', '삼척시'),
       (get_city_id('32'), '32', '홍천군'),
       (get_city_id('32'), '33', '횡성군'),
       (get_city_id('32'), '35', '영월군'),
       (get_city_id('32'), '36', '평창군'),
       (get_city_id('32'), '37', '정선군'),
       (get_city_id('32'), '38', '철원군'),
       (get_city_id('32'), '39', '화천군'),
       (get_city_id('32'), '40', '양구군'),
       (get_city_id('32'), '41', '인제군'),
       (get_city_id('32'), '42', '고성군'),
       (get_city_id('32'), '43', '양양군'),
       (get_city_id('32'), '44', '명주군'),
       (get_city_id('32'), 'ZZ', '강원전역');

-- Insert districts for 충북 (Chungbuk)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('33'), '00', '전체'),
       (get_city_id('33'), '20', '청주시'),
       (get_city_id('33'), '12', '충주시'),
       (get_city_id('33'), '13', '제천시'),
       (get_city_id('33'), '32', '보은군'),
       (get_city_id('33'), '33', '옥천군'),
       (get_city_id('33'), '34', '영동군'),
       (get_city_id('33'), '35', '진천군'),
       (get_city_id('33'), '36', '괴산군'),
       (get_city_id('33'), '37', '음성군'),
       (get_city_id('33'), '40', '단양군'),
       (get_city_id('33'), '42', '증평군'),
       (get_city_id('33'), 'ZZ', '충북전역');

-- Insert districts for 충남 (Chungnam)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('34'), '00', '전체'),
       (get_city_id('34'), '11', '천안시'),
       (get_city_id('34'), '12', '공주시'),
       (get_city_id('34'), '15', '서산시'),
       (get_city_id('34'), '16', '아산시'),
       (get_city_id('34'), '17', '보령시'),
       (get_city_id('34'), '18', '계룡시'),
       (get_city_id('34'), '31', '금산군'),
       (get_city_id('34'), '35', '논산시'),
       (get_city_id('34'), '36', '부여군'),
       (get_city_id('34'), '37', '서천군'),
       (get_city_id('34'), '39', '청양군'),
       (get_city_id('34'), '40', '홍성군'),
       (get_city_id('34'), '41', '예산군'),
       (get_city_id('34'), '43', '당진시'),
       (get_city_id('34'), '46', '태안군'),
       (get_city_id('34'), 'ZZ', '충남전역');

-- Insert districts for 전북 (Jeonbuk)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('35'), '00', '전체'),
       (get_city_id('35'), '11', '전주시'),
       (get_city_id('35'), '12', '군산시'),
       (get_city_id('35'), '15', '남원시'),
       (get_city_id('35'), '16', '김제시'),
       (get_city_id('35'), '17', '정읍시'),
       (get_city_id('35'), '18', '익산시'),
       (get_city_id('35'), '31', '완주군'),
       (get_city_id('35'), '32', '진안군'),
       (get_city_id('35'), '33', '무주군'),
       (get_city_id('35'), '34', '장수군'),
       (get_city_id('35'), '35', '임실군'),
       (get_city_id('35'), '37', '순창군'),
       (get_city_id('35'), '39', '고창군'),
       (get_city_id('35'), '40', '부안군'),
       (get_city_id('35'), 'ZZ', '전북전역');

-- Insert districts for 전남 (Jeonnam)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('36'), '00', '전체'),
       (get_city_id('36'), '11', '목포시'),
       (get_city_id('36'), '12', '여수시'),
       (get_city_id('36'), '13', '순천시'),
       (get_city_id('36'), '14', '나주시'),
       (get_city_id('36'), '15', '여천시'),
       (get_city_id('36'), '17', '광양시'),
       (get_city_id('36'), '32', '담양군'),
       (get_city_id('36'), '33', '곡성군'),
       (get_city_id('36'), '34', '구례군'),
       (get_city_id('36'), '36', '여천군'),
       (get_city_id('36'), '38', '고흥군'),
       (get_city_id('36'), '39', '보성군'),
       (get_city_id('36'), '40', '화순군'),
       (get_city_id('36'), '41', '장흥군'),
       (get_city_id('36'), '42', '강진군'),
       (get_city_id('36'), '43', '해남군'),
       (get_city_id('36'), '44', '영암군'),
       (get_city_id('36'), '45', '무안군'),
       (get_city_id('36'), '47', '함평군'),
       (get_city_id('36'), '48', '영광군'),
       (get_city_id('36'), '49', '장성군'),
       (get_city_id('36'), '50', '완도군'),
       (get_city_id('36'), '51', '진도군'),
       (get_city_id('36'), '52', '신안군'),
       (get_city_id('36'), '53', '승주군'),
       (get_city_id('36'), 'ZZ', '전남전역');

-- Insert districts for 경북 (Gyeongbuk)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('37'), '00', '전체'),
       (get_city_id('37'), '11', '포항시'),
       (get_city_id('37'), '12', '경주시'),
       (get_city_id('37'), '13', '김천시'),
       (get_city_id('37'), '14', '안동시'),
       (get_city_id('37'), '15', '구미시'),
       (get_city_id('37'), '16', '영주시'),
       (get_city_id('37'), '17', '영천시'),
       (get_city_id('37'), '18', '상주시'),
       (get_city_id('37'), '20', '경산시'),
       (get_city_id('37'), '21', '문경시'),
       (get_city_id('37'), '33', '의성군'),
       (get_city_id('37'), '35', '청송군'),
       (get_city_id('37'), '36', '영양군'),
       (get_city_id('37'), '37', '영덕군'),
       (get_city_id('37'), '42', '청도군'),
       (get_city_id('37'), '43', '고령군'),
       (get_city_id('37'), '44', '성주군'),
       (get_city_id('37'), '45', '칠곡군'),
       (get_city_id('37'), '50', '예천군'),
       (get_city_id('37'), '52', '봉화군'),
       (get_city_id('37'), '53', '울진군'),
       (get_city_id('37'), '54', '울릉군'),
       (get_city_id('37'), 'ZZ', '경북전역');

-- Insert districts for 경남 (Gyeongnam)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('38'), '00', '전체'),
       (get_city_id('38'), '13', '진주시'),
       (get_city_id('38'), '50', '창원시'),
       (get_city_id('38'), '18', '김해시'),
       (get_city_id('38'), '22', '밀양시'),
       (get_city_id('38'), '25', '통영시'),
       (get_city_id('38'), '26', '거제시'),
       (get_city_id('38'), '27', '사천시'),
       (get_city_id('38'), '32', '의령군'),
       (get_city_id('38'), '33', '함안군'),
       (get_city_id('38'), '34', '창녕군'),
       (get_city_id('38'), '36', '양산시'),
       (get_city_id('38'), '39', '의창군'),
       (get_city_id('38'), '42', '고성군'),
       (get_city_id('38'), '44', '남해군'),
       (get_city_id('38'), '45', '하동군'),
       (get_city_id('38'), '46', '산청군'),
       (get_city_id('38'), '47', '함양군'),
       (get_city_id('38'), '48', '거창군'),
       (get_city_id('38'), '49', '합천군'),
       (get_city_id('38'), 'ZZ', '경남전역');

-- Insert districts for 제주 (Jeju)
INSERT INTO public.districts (city_id, code, name)
VALUES (get_city_id('50'), '00', '전체'),
       (get_city_id('50'), '01', '제주시'),
       (get_city_id('50'), '02', '서귀포시'),
       (get_city_id('50'), 'ZZ', '제주전역');

-- ===================================================
-- 6. Create the 'heritage_types' Table with Integer Primary Keys
-- ===================================================

CREATE TABLE public.heritage_types
(
    id   SERIAL PRIMARY KEY,           -- Auto-incremented integer ID
    code VARCHAR(2)   NOT NULL UNIQUE, -- e.g., '11', '12', etc.
    name VARCHAR(255) NOT NULL UNIQUE  -- e.g., '국보', '보물', etc.
);

-- ===================================================
-- 7. Populate the 'heritage_types' Table
-- ===================================================

INSERT INTO public.heritage_types (code, name)
VALUES ('11', '국보'),      -- NATIONAL_TREASURE
       ('12', '보물'),      -- TREASURE
       ('13', '사적'),      -- HISTORIC_SITE
       ('14', '사적및명승'),   -- HISTORIC_AND_SCENIC_SITE
       ('15', '명승'),      -- SCENIC_SITE
       ('16', '천연기념물'),   -- NATURAL_MONUMENT
       ('17', '국가무형문화재'), -- INTANGIBLE_HERITAGE
       ('18', '국가민속문화재'), -- FOLKLORE_HERITAGE
       ('21', '시도유형문화재'), -- REGIONAL_HERITAGE
       ('22', '시도무형문화재'), -- REGIONAL_INTANGIBLE_HERITAGE
       ('23', '시도기념물'),   -- REGIONAL_MONUMENT
       ('24', '시도민속문화재'), -- REGIONAL_FOLKLORE_HERITAGE
       ('25', '시도등록문화재'), -- REGIONAL_REGISTERED_HERITAGE
       ('31', '문화재자료'),   -- HERITAGE_MATERIAL
       ('79', '국가등록문화재'), -- NATIONAL_REGISTERED_HERITAGE
       ('80', '이북5도무형문화재');
-- NORTH_KOREAN_INTANGIBLE_HERITAGE

-- ===================================================
-- 8. Create the 'heritage_items' Table with Geospatial Support and Reference to 'heritage_types'
-- ===================================================
-- Create the hierarchical 'categories' table
CREATE TABLE public.categories
(
    id        SERIAL PRIMARY KEY,
    name      VARCHAR(255) NOT NULL,
    parent_id INTEGER REFERENCES public.categories (id) ON DELETE CASCADE,
    level     INTEGER      NOT NULL CHECK (level BETWEEN 1 AND 4),
    UNIQUE (name, parent_id)
);

CREATE TABLE public.heritage_items
(
    id                   UUID PRIMARY KEY         DEFAULT gen_random_uuid(),
    uid                  VARCHAR(255) UNIQUE NOT NULL, -- Store the enum value
    name                 VARCHAR(255)        NOT NULL,
    name_hanja           VARCHAR(255),
    city_id              INTEGER             NOT NULL REFERENCES public.cities (id),
    district_id          INTEGER             NOT NULL REFERENCES public.districts (id),
    heritage_type_id     INTEGER             NOT NULL REFERENCES public.heritage_types (id),
    canceled             BOOLEAN                  DEFAULT FALSE,
    last_modified        DATE,
    management_number    VARCHAR(50),
    linkage_number       VARCHAR(50),
    longitude            DOUBLE PRECISION,
    latitude             DOUBLE PRECISION,
    location             GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
    ) STORED,
    type                 VARCHAR(255),
    quantity             VARCHAR(255),
    registered_date      DATE,
    location_description TEXT,
    era                  VARCHAR(255),
    owner                VARCHAR(255),
    manager              VARCHAR(255),
    thumbnail            TEXT,
    content              TEXT,
    category1_id         INTEGER REFERENCES public.categories (id),
    category2_id         INTEGER REFERENCES public.categories (id),
    category3_id         INTEGER REFERENCES public.categories (id),
    category4_id         INTEGER REFERENCES public.categories (id),
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===================================================
-- 9. Create media Table
-- ===================================================

-- Create the 'images' table
CREATE TABLE public.images
(
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    heritage_item_id UUID REFERENCES public.heritage_items (id) ON DELETE CASCADE,
    image_license    VARCHAR(255),
    image_url        VARCHAR(1024),
    description      TEXT
);

-- Create the 'videos' table
CREATE TABLE public.videos
(
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    heritage_item_id UUID REFERENCES public.heritage_items (id) ON DELETE CASCADE,
    video_url        VARCHAR(1024)
);

-- ===================================================
-- 10. Indexing for Performance Optimization
-- ===================================================

-- Index on heritage_items.city_id for faster lookups by city
CREATE INDEX idx_heritage_items_city_id ON public.heritage_items (city_id);

-- Index on heritage_items.district_id for faster lookups by district
CREATE INDEX idx_heritage_items_district_id ON public.heritage_items (district_id);

-- Index on heritage_items.heritage_type_id for faster lookups by heritage type
CREATE INDEX idx_heritage_items_heritage_type_id ON public.heritage_items (heritage_type_id);

-- Composite index on city_id and district_id for combined queries
CREATE INDEX idx_heritage_items_city_district ON public.heritage_items (city_id, district_id);

-- Geospatial index on location for efficient geospatial queries
CREATE INDEX idx_heritage_items_location ON public.heritage_items USING GIST(location);

-- ===================================================
-- 11. Make 'cities', 'districts', and 'heritage_types' Tables Immutable
-- ===================================================

-- Revoke all privileges on 'cities' from PUBLIC
REVOKE ALL ON TABLE public.cities FROM PUBLIC;

-- Grant only SELECT privilege on 'cities' to PUBLIC
GRANT SELECT ON TABLE public.cities TO PUBLIC;

-- Revoke all privileges on 'districts' from PUBLIC
REVOKE ALL ON TABLE public.districts FROM PUBLIC;

-- Grant only SELECT privilege on 'districts' to PUBLIC
GRANT SELECT ON TABLE public.districts TO PUBLIC;

-- Revoke all privileges on 'heritage_types' from PUBLIC
REVOKE ALL ON TABLE public.heritage_types FROM PUBLIC;

-- Grant only SELECT privilege on 'heritage_types' to PUBLIC
GRANT SELECT ON TABLE public.heritage_types TO PUBLIC;

-- Revoke all privileges on 'heritage_items' from PUBLIC
REVOKE ALL ON TABLE public.heritage_items FROM PUBLIC;

-- Grant only SELECT privilege on 'heritage_items' to PUBLIC
GRANT SELECT ON TABLE public.heritage_items TO PUBLIC;

-- Revoke all privileges on 'categories' from PUBLIC
REVOKE ALL ON TABLE public.categories FROM PUBLIC;

-- Grant only SELECT privilege on 'categories' to PUBLIC
GRANT SELECT ON TABLE public.categories TO PUBLIC;

-- Revoke all privileges on 'images' from PUBLIC
REVOKE ALL ON TABLE public.images FROM PUBLIC;

-- Grant only SELECT privilege on 'images' to PUBLIC
GRANT SELECT ON TABLE public.images TO PUBLIC;

-- Revoke all privileges on 'videos' from PUBLIC
REVOKE ALL ON TABLE public.videos FROM PUBLIC;

-- Grant only SELECT privilege on 'videos' to PUBLIC
GRANT SELECT ON TABLE public.videos TO PUBLIC;

-- ===================================================
-- 12. Create a Function to Retrieve City ID
-- ===================================================

ALTER FUNCTION public.get_city_id(VARCHAR (2))
    SET search_path = public;
