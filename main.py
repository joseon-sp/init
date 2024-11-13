from kheritageapi.heritage import HeritageSearcher, HeritageInfo
from kheritageapi.models import HeritagSearchResultItem, HeritageDetail, HeritageVideoSet, HeritageImageSet, \
    HeritageImageItem

search = HeritageSearcher(result_count=10, page_index=1)
results: HeritagSearchResultItem = search.perform_search()
print(results.hits)  # total count of search results

for (result) in results.items:
    item: HeritageInfo = HeritageInfo(result)
    detail: HeritageDetail = item.retrieve_detail()
    images: HeritageImageSet = item.retrieve_image()
    videos: HeritageVideoSet = item.retrieve_video()

    print(detail)

    for (img) in images:
        image: HeritageImageItem = img
        print(image)

    for (vid) in videos:
        print(vid)
