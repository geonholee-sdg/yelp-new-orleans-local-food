# Where to find the best local food in New Orleans

Math 167R, Project 2. Geonho Lee.

Where can a visitor find the best local food in New Orleans (Cajun/Creole, Seafood and Southern restaurants), and which part of the city is the best place to look for it?

**[Read the analysis so far (steps 1 to 6)](yelp_new_orleans_project.md)**: category choice, review join, city boundary check, and the comparison of ZIP codes, census tracts and neighborhoods with maps. Step 7 and the final top 10 are next. The same report as a single HTML file is [`yelp_new_orleans_project.html`](yelp_new_orleans_project.html) (download it to view).

## Files

- `R/import.R` reads the two big Yelp json files, keeps New Orleans restaurants and their reviews, and saves them as compressed rds files in `data/new_orleans/`.
- `R/boundaries.R` downloads the boundary files (Louisiana places, Orleans Parish census tracts, 701 ZIP codes, New Orleans neighborhoods) and saves them in `data/boundaries/`.
- `yelp_new_orleans_project.qmd` is the analysis. `yelp_new_orleans_project.md` is the rendered version you can read on GitHub, and `yelp_new_orleans_project.html` is the same thing as one self contained HTML file.
- `data/new_orleans/business_new_orleans.rds` is the New Orleans restaurant table (2,259 restaurants).
- `data/new_orleans/reviews_new_orleans_no_text.rds` has every review for those restaurants (476,421), without the review text. The version with text doesn't fit on GitHub, so it stays on my computer.

## Getting the data

1. Download the Yelp Open Dataset from https://business.yelp.com/data/resources/open-dataset/ (about 4 GB zipped).
2. Unzip it and put the json files in `data/raw/`.
3. Open the project in RStudio and run `R/import.R`, then `R/boundaries.R`.
4. Render `yelp_new_orleans_project.qmd`.

The raw json files are not in this repo. They are about 9 GB unzipped, way over what GitHub allows, so `data/raw/` is in `.gitignore`.

## Handling the large files

The business file (120 MB) reads fine in one go. The review file is 5 GB and reading it all at once was not going to work on a laptop, so `import.R` reads it 20,000 lines at a time with `stream_in()` and a handler that keeps only the rows for New Orleans restaurants. Memory never goes above a few hundred MB that way. The whole import took about 6 minutes. After that everything runs off the rds files, which are under 8 MB together, and the raw files can be deleted.
