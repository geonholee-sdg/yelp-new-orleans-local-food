# boundaries.R
# Downloads the boundary files I need for step 5 and 6 and saves them as rds files
# in data/boundaries. Run once. Needs internet. Takes a few minutes, the ZIP code
# file is the slow one because the census only ships it as one national file.

library(sf)
library(tigris)
library(dplyr)

options(tigris_use_cache = TRUE)
dir.create("data/boundaries", showWarnings = FALSE)

# ---- Louisiana places (for the official New Orleans city boundary) ----
places <- tryCatch(
  tigris::places(state = "LA", cb = TRUE, year = 2024, class = "sf"),
  error = function(e) tigris::places(state = "LA", cb = TRUE, year = 2023, class = "sf")
)
places <- places |> select(GEOID, place_name = NAME)
saveRDS(places, "data/boundaries/louisiana_places.rds")
cat("places:", nrow(places), "\n")

# ---- census tracts for Orleans Parish ----
tracts <- tryCatch(
  tigris::tracts(state = "LA", county = "Orleans", cb = TRUE, year = 2024, class = "sf"),
  error = function(e) tigris::tracts(state = "LA", county = "Orleans", cb = TRUE, year = 2023, class = "sf")
)
tracts <- tracts |> select(GEOID, tract_name = NAME)
saveRDS(tracts, "data/boundaries/orleans_tracts.rds")
cat("tracts:", nrow(tracts), "\n")

# ---- ZIP code areas (ZCTAs) that start with 701 ----
# zctas() with cb = TRUE only has the 2020 version, and it downloads the whole
# country (about 70 MB) before filtering, so this one takes a while
zips <- tigris::zctas(cb = TRUE, year = 2020, starts_with = "701", class = "sf")
zips <- zips |> select(zcta = ZCTA5CE20)
saveRDS(zips, "data/boundaries/zctas_701.rds")
cat("zctas:", nrow(zips), "\n")

# ---- Neighborhood Statistical Areas from the city's open data site ----
nsa_url <- "https://data.nola.gov/api/geospatial/exvn-jeh2?method=export&format=GeoJSON"
nsa <- sf::st_read(nsa_url, quiet = TRUE)
print(names(nsa))
saveRDS(nsa, "data/boundaries/neighborhoods.rds")
cat("neighborhoods:", nrow(nsa), "\n")

sizes <- file.info(list.files("data/boundaries", full.names = TRUE))
print(data.frame(file = basename(rownames(sizes)), MB = round(sizes$size / 1e6, 2)))
