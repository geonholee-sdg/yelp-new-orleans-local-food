# import.R
# Step 1 and 2 of project 2. Reads the two yelp json files, keeps the New Orleans
# restaurants and their reviews, and saves them as rds files in data/new_orleans.
# The review file is 5 GB so this takes a while.

library(tidyverse)
library(jsonlite)

business_file <- "data/raw/yelp_academic_dataset_business.json"
review_file <- "data/raw/yelp_academic_dataset_review.json"

dir.create("data/new_orleans", recursive = TRUE, showWarnings = FALSE)

start_time <- Sys.time()

# ---- Step 1: business file ----
# about 120 MB, fits in memory fine
business_raw <- jsonlite::stream_in(file(business_file), verbose = FALSE)
print(dim(business_raw))
print(names(business_raw))

business <- business_raw |>
  select(
    business_id, name, address, city, state, postal_code,
    latitude, longitude, stars, review_count, is_open, categories
  )
rm(business_raw)

# which cities/states are even in here
print(head(sort(table(business$state), decreasing = TRUE), 12))

# ---- Step 2: New Orleans restaurants ----
new_orleans_restaurants <- business |>
  filter(
    state == "LA",
    city == "New Orleans",
    !is.na(categories),
    str_detect(categories, regex("Restaurants", ignore_case = TRUE))
  ) |>
  mutate(
    postal_code = na_if(postal_code, ""),
    categories = str_squish(categories),
    business_name = str_squish(name)
  ) |>
  distinct(business_id, .keep_all = TRUE)

new_orleans_restaurants |>
  summarise(
    number_of_restaurants = n(),
    missing_latitude = sum(is.na(latitude)),
    missing_longitude = sum(is.na(longitude)),
    missing_categories = sum(is.na(categories))
  ) |>
  print()

glimpse(new_orleans_restaurants)

saveRDS(
  new_orleans_restaurants,
  "data/new_orleans/business_new_orleans.rds",
  compress = "xz"
)

# ---- Step 1 again, for the review file ----
# The review file is 5 GB, too big to read all at once on my laptop. So I read it
# 20,000 lines at a time and only keep the rows that belong to a New Orleans
# restaurant. That way only the small kept part ever sits in memory.
keep_ids <- new_orleans_restaurants$business_id
kept <- list()
lines_read <- 0

keep_new_orleans <- function(chunk) {
  lines_read <<- lines_read + nrow(chunk)
  rows <- chunk[chunk$business_id %in% keep_ids, ]
  if (nrow(rows) > 0) kept[[length(kept) + 1]] <<- rows
  if (lines_read %% 500000 == 0) cat("read", lines_read, "reviews so far\n")
}

jsonlite::stream_in(file(review_file), handler = keep_new_orleans, pagesize = 20000, verbose = FALSE)

reviews <- bind_rows(kept) |>
  select(business_id, user_id, stars, date, text, useful, funny, cool)
rm(kept)

cat("reviews in the whole file:", lines_read, "\n")
cat("reviews for New Orleans restaurants:", nrow(reviews), "\n")
glimpse(reviews)

# the version with review text stays on my computer, it is too big for github
saveRDS(reviews, "data/new_orleans/reviews_new_orleans.rds", compress = "xz")

# this smaller version without the text is the one that goes on github
reviews |>
  select(-text) |>
  saveRDS("data/new_orleans/reviews_new_orleans_no_text.rds", compress = "xz")

# file sizes and how long it took
sizes <- file.info(list.files("data/new_orleans", full.names = TRUE))
print(data.frame(file = basename(rownames(sizes)), MB = round(sizes$size / 1e6, 1)))
print(Sys.time() - start_time)

# read it back in later
# new_orleans_restaurants <- readRDS("data/new_orleans/business_new_orleans.rds")
# reviews <- readRDS("data/new_orleans/reviews_new_orleans.rds")
