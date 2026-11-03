# Yelp New Orleans: local food

Math 167R, Project 2. Geonho Lee.

Right now this repo has Step 1 and 2 of the project (that was Homework 5): importing the Yelp data and cutting it down to New Orleans restaurants. The analysis comes next.

## Files

- `R/import.R` reads the two big Yelp json files, keeps New Orleans restaurants and their reviews, and saves them as compressed rds files in `data/new_orleans/`.
- `data/new_orleans/business_new_orleans.rds` is the New Orleans restaurant table.
- `data/new_orleans/reviews_new_orleans_no_text.rds` has every review for those restaurants, without the review text. The version with text doesn't fit on GitHub, so it stays on my computer as `reviews_new_orleans.rds`.

## Getting the data

1. Download the Yelp Open Dataset from https://business.yelp.com/data/resources/open-dataset/ (about 4 GB zipped).
2. Unzip it and put the json files in `data/raw/`.
3. Open the project in RStudio and run `R/import.R`. The review file alone is 5 GB, so it takes a while.

The raw json files are not in this repo. They are about 9 GB unzipped, way over what GitHub allows, so `data/raw/` is in `.gitignore`.
