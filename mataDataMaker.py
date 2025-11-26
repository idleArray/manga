import os
import re
from pathlib import Path

# Root folder
root = Path("/vault/homework/comics/hentai")  # <-- change this to your manga root

def parse_number_from_title(title: str) -> str:
    # Look for trailing number or number range
    match = re.search(r'(\d+)(-\d+)?$', title)
    if not match:
        return "1"  # default if no number
    if match.group(2):  # if it's a range like 1-3
        return "1"      # treat range as standalone
    return match.group(1)  # return the plain number

for author_folder in root.iterdir():
    if author_folder.is_dir():
        author_name = author_folder.name
        for work_folder in author_folder.iterdir():
            if work_folder.is_dir():
                comicinfo_path = work_folder / "ComicInfo.xml"
                if comicinfo_path.exists():
                    print(f"Skipping {work_folder} (ComicInfo.xml already exists)")
                    continue

                work_title = work_folder.name
                number = parse_number_from_title(work_title)

                # Count image files
                image_files = [f for f in work_folder.iterdir() if f.suffix.lower() in [".png", ".jpg", ".jpeg"]]
                page_count = len(image_files)

                comicinfo_content = f"""<ComicInfo>
  <Title>{work_title}</Title>
  <Series>{work_title}</Series>
  <Number>{number}</Number>
  <Writer>{author_name}</Writer>
  <Publisher></Publisher>
  <Genre></Genre>
  <Summary></Summary>
  <Language>English</Language>
  <PageCount>{page_count}</PageCount>
  <Year></Year>
  <Cover>0.png</Cover>
</ComicInfo>"""

                with open(comicinfo_path, "w", encoding="utf-8") as f:
                    f.write(comicinfo_content)

                print(f"Generated ComicInfo.xml for {work_folder} with Number={number}")