# AI prompts

I used Claude on this project for code and for checking my work against the instructions. I ran the import and every render on my own laptop, compared the printed counts with the report, and looked at each table and map before it went into the repo. Below are the prompts where I asked again and something changed.

## 1. Reading the instructions

**Ask:** go through the project instructions and list every requirement and every number in them.

The list covered the ten deliverables and the README checklist, but not how the code should look. So I asked again: what coding style and report style do the instructions use?

**Result:** the code follows the professor's examples: `stream_in()` with `file()`, `str_detect()` with `regex(ignore_case = TRUE)`, `st_as_sf()` and `st_join(join = st_within, left = TRUE)`, `kable()` tables, long snake_case names like `number_of_reviews_all_reviewers`, and `viridis` option C with limits 1 to 5 for the star maps.

## 2. The 5 GB review file

**Ask:** write the import so it follows steps 1 and 2 and does not hold the whole review file in memory.

The script reads the review file 20,000 lines at a time and keeps only New Orleans restaurants. I ran it and checked the printed counts: 2,259 restaurants, 476,421 reviews, about 6 minutes. The file with the review text was too big for GitHub, so I asked for a second copy without the text. That is the one in the repo.

## 3. Comparing the geographic systems

**Ask:** compare ZIP codes, census tracts and the neighborhoods using the seven checks in step 6.

Then I asked for the table to be checked against the instructions again. The ZIP layer still had Jefferson Parish ZIP codes in it, so the number of areas was not comparable across the three systems.

**Result:** the ZIP layer is limited to the ZCTAs that touch the city boundary, and the table has an "Areas with 0" column.

## 4. The reviewer threshold

**Ask:** build step 7 with the 5 review threshold and show how the threshold changes the results.

The first version only showed how many reviewers are left at each threshold. The instructions ask how the results change, so I asked for the ranking to be rebuilt at 3, 5 and 10.

**Result:** the "Does the threshold change the answer?" table. The exact top 10 changes a lot, but the neighborhood ranks barely move, so the answer leans on the neighborhoods.

## 5. The top 10 floor

With a floor of 5 regular reviews, the top of the list was places with only 6 or 7. I asked what happens with a higher floor. The final top 10 uses 10 regular reviews, explains why, and shows the plain average and both review counts next to every score.

## 6. Final check

**Ask:** check every number in the text against the output and point out anything that reads as padding.

**Result:** a repeated table and some bold labels came out, and every number in the README now matches the rendered report.
