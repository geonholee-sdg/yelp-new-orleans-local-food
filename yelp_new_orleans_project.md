# Where to find the best local food in New Orleans
Geonho Lee
2026-11-10

- [The question](#the-question)
- [Step 1 and 2: import and filter](#step-1-and-2-import-and-filter)
- [Step 3: pick the restaurant
  categories](#step-3-pick-the-restaurant-categories)
  - [Why these three](#why-these-three)
  - [Do they actually appear
    together?](#do-they-actually-appear-together)
  - [Inclusion rule](#inclusion-rule)
- [Step 4: join the reviews](#step-4-join-the-reviews)
- [Step 5: check the city label against the real city
  boundary](#step-5-check-the-city-label-against-the-real-city-boundary)
- [Step 6: choose and defend a geographic
  area](#step-6-choose-and-defend-a-geographic-area)
  - [What the table says](#what-the-table-says)
  - [My choice: Neighborhood Statistical
    Areas](#my-choice-neighborhood-statistical-areas)
  - [Neighborhoods ranked by local food
    restaurants](#neighborhoods-ranked-by-local-food-restaurants)

## The question

Where can a visitor find the best local food in New Orleans
(Cajun/Creole, Seafood and Southern restaurants), and which part of the
city is the best place to look for it?

I picked local food because that is what people actually come to New
Orleans to eat. Steps 1 to 6 are below. Step 7 (reviewer adjusted
ratings) and the final top 10 come next.

## Step 1 and 2: import and filter

The import is in [`R/import.R`](R/import.R). It reads the two Yelp json
files with `stream_in()`, keeps businesses in New Orleans, LA whose
categories include “Restaurants”, and saves the result as rds. The
review file is 5 GB, so that one is read 20,000 lines at a time and only
the rows for New Orleans restaurants are kept. Details and the large
data notes are in the README.

``` r
restaurants <- readRDS("data/new_orleans/business_new_orleans.rds")
reviews <- readRDS("data/new_orleans/reviews_new_orleans_no_text.rds")

dim(restaurants)
```

    [1] 2259   13

``` r
dim(reviews)
```

    [1] 476421      7

2,259 restaurants and 476,421 reviews. Every restaurant has a latitude
and longitude, which matters for the maps later.

## Step 3: pick the restaurant categories

The `categories` column is one string with commas in it, so first I
split it into one row per restaurant and category.

``` r
restaurant_categories <- restaurants |>
  select(business_id, categories) |>
  separate_rows(categories, sep = ",") |>
  mutate(category = str_to_lower(str_squish(categories))) |>
  select(business_id, category) |>
  distinct()

category_counts <- restaurant_categories |>
  count(category, sort = TRUE)

category_counts |>
  filter(category != "restaurants") |>
  slice_head(n = 20) |>
  kable(col.names = c("Category", "Restaurants"))
```

| Category                  | Restaurants |
|:--------------------------|------------:|
| food                      |         725 |
| nightlife                 |         540 |
| bars                      |         508 |
| cajun/creole              |         401 |
| breakfast & brunch        |         367 |
| sandwiches                |         354 |
| seafood                   |         331 |
| american (new)            |         323 |
| american (traditional)    |         299 |
| coffee & tea              |         208 |
| burgers                   |         202 |
| cafes                     |         173 |
| pizza                     |         172 |
| cocktail bars             |         160 |
| event planning & services |         156 |
| southern                  |         155 |
| fast food                 |         142 |
| mexican                   |         124 |
| salad                     |         124 |
| italian                   |         121 |

“Restaurants” is on every row because that is how I filtered, so I
dropped it from the table. After that the biggest categories are things
like food, nightlife and bars, which are not really cuisines. The first
real cuisine is cajun/creole at number 5, and seafood and southern are
not far behind.

### Why these three

Cajun/Creole, Seafood and Southern are the three categories that
describe New Orleans food. Gumbo, po-boys, crawfish, red beans and rice,
fried catfish all land in one or more of these. They also overlap a lot
in real life: a Cajun place usually serves seafood, and a lot of seafood
places call themselves Southern.

``` r
selected_categories <- c("cajun/creole", "seafood", "southern")

category_counts |>
  filter(category %in% selected_categories) |>
  kable(col.names = c("Category", "Restaurants"))
```

| Category     | Restaurants |
|:-------------|------------:|
| cajun/creole |         401 |
| seafood      |         331 |
| southern     |         155 |

### Do they actually appear together?

``` r
selected_wide <- restaurant_categories |>
  filter(category %in% selected_categories) |>
  mutate(has = TRUE) |>
  pivot_wider(names_from = category, values_from = has, values_fill = FALSE)

pair_counts <- tribble(
  ~pair, ~restaurants,
  "cajun/creole + seafood",  sum(selected_wide$`cajun/creole` & selected_wide$seafood),
  "cajun/creole + southern", sum(selected_wide$`cajun/creole` & selected_wide$southern),
  "seafood + southern",      sum(selected_wide$seafood & selected_wide$southern),
  "all three",               sum(selected_wide$`cajun/creole` & selected_wide$seafood & selected_wide$southern)
)

kable(pair_counts, col.names = c("Categories", "Restaurants with both"))
```

| Categories              | Restaurants with both |
|:------------------------|----------------------:|
| cajun/creole + seafood  |                   156 |
| cajun/creole + southern |                    72 |
| seafood + southern      |                    45 |
| all three               |                    34 |

``` r
how_many <- selected_wide |>
  mutate(n_selected = `cajun/creole` + seafood + southern) |>
  count(n_selected)

kable(how_many, col.names = c("How many of the three", "Restaurants"))
```

| How many of the three | Restaurants |
|----------------------:|------------:|
|                     1 |         443 |
|                     2 |         171 |
|                     3 |          34 |

156 restaurants are tagged both cajun/creole and seafood, so the overlap
is real. 205 restaurants have at least two of the three tags. That is
the evidence the three belong in one group.

### Inclusion rule

A restaurant is in my group if it has **at least one** of the three
categories. Requiring two would throw out most of the plain seafood
places and plain Southern places, and those are exactly the kind of
restaurant a visitor is looking for.

``` r
selected_restaurants <- restaurants |>
  semi_join(selected_wide, by = "business_id")

n_selected <- nrow(selected_restaurants)
n_open <- sum(selected_restaurants$is_open == 1)
```

That gives 648 local food restaurants, 420 of them still open according
to Yelp. That is 29% of all New Orleans restaurants in the dataset. I
keep the closed ones for the counts and maps in this part, since the
question for step 6 is where local food restaurants are, not where to
eat tonight.

## Step 4: join the reviews

Filter the reviews down to the selected restaurants first, then join. No
reason to carry the other 476,421 reviews around.

``` r
local_reviews <- reviews |>
  semi_join(selected_restaurants, by = "business_id") |>
  mutate(review_date = ymd_hms(date), review_year = year(review_date))

reviews_per_restaurant <- local_reviews |>
  count(business_id, name = "reviews_in_dataset")

selected_restaurants <- selected_restaurants |>
  left_join(reviews_per_restaurant, by = "business_id") |>
  mutate(reviews_in_dataset = replace_na(reviews_in_dataset, 0))

summary(selected_restaurants$reviews_in_dataset)
```

       Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
       5.00   28.75  115.00  383.37  395.25 7673.00 

248,426 reviews from 138,073 reviewers, from 2005 to 2022. That is 52%
of all the New Orleans restaurant reviews, for 29% of the restaurants.
Local food places get reviewed more than average.

One check: Yelp’s own `review_count` column counts all reviews ever,
while the dataset only includes a subset of them.

``` r
review_check <- selected_restaurants |>
  summarise(
    yelp_review_count = sum(review_count),
    reviews_in_dataset = sum(reviews_in_dataset),
    ratio = reviews_in_dataset / yelp_review_count
  )

kable(review_check, digits = 2)
```

| yelp_review_count | reviews_in_dataset | ratio |
|------------------:|-------------------:|------:|
|            243635 |             248426 |  1.02 |

The two are close (ratio 1.02), so the review file and the business file
were taken at about the same time. I use the dataset count from here on
because those are the reviews I can actually look at.

## Step 5: check the city label against the real city boundary

Yelp’s `city` column is typed in by whoever created the listing. The
census has an official polygon for New Orleans. A spatial join tells me
which restaurants labeled “New Orleans” are actually inside it. The
boundary files were downloaded once with
[`R/boundaries.R`](R/boundaries.R) and saved as rds.

``` r
louisiana_places <- readRDS("data/boundaries/louisiana_places.rds") |> st_transform(4326)
new_orleans_boundary <- louisiana_places |> filter(place_name == "New Orleans")

restaurant_points <- selected_restaurants |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)

restaurants_with_place <- restaurant_points |>
  st_join(louisiana_places, join = st_within, left = TRUE)

restaurants_with_place |>
  st_drop_geometry() |>
  count(city, place_name, sort = TRUE) |>
  kable(col.names = c("Yelp city", "Census place the point is in", "Restaurants"))
```

| Yelp city   | Census place the point is in | Restaurants |
|:------------|:-----------------------------|------------:|
| New Orleans | New Orleans                  |         632 |
| New Orleans | Harahan                      |           4 |
| New Orleans | Jefferson                    |           4 |
| New Orleans | Elmwood                      |           2 |
| New Orleans | Arabi                        |           1 |
| New Orleans | Gretna                       |           1 |
| New Orleans | Harvey                       |           1 |
| New Orleans | Kenner                       |           1 |
| New Orleans | Metairie                     |           1 |
| New Orleans | River Ridge                  |           1 |

``` r
n_inside <- sum(restaurants_with_place$place_name == "New Orleans", na.rm = TRUE)
n_outside <- n_selected - n_inside
```

``` r
outside_places <- restaurants_with_place |>
  st_drop_geometry() |>
  filter(is.na(place_name) | place_name != "New Orleans") |>
  mutate(place_name = replace_na(place_name, "none")) |>
  count(place_name, sort = TRUE)

outside_named <- outside_places |> filter(place_name != "none")
n_no_place <- sum(outside_places$n[outside_places$place_name == "none"])
outside_text <- paste0(outside_named$place_name, " (", outside_named$n, ")", collapse = ", ")
```

632 of the 648 are inside the official New Orleans boundary. The other
16 say “New Orleans” on Yelp but the pin lands in Harahan (4), Jefferson
(4), Elmwood (2), Arabi (1), Gretna (1), Harvey (1), Kenner (1),
Metairie (1), River Ridge (1). Those are suburbs that use a New Orleans
mailing address, so the pin is probably right and the city label is just
loose. They stay in the dataset, but for the geographic comparison I
only count restaurants inside the city, since that is the question.

``` r
ggplot() +
  geom_sf(data = new_orleans_boundary, fill = "grey95", color = "grey35") +
  geom_sf(
    data = restaurants_with_place |> filter(place_name == "New Orleans"),
    aes(color = stars), alpha = 0.7, size = 1.6
  ) +
  scale_color_viridis_c(option = "C", limits = c(1, 5)) +
  labs(title = "Local food restaurants inside New Orleans", color = "Yelp\nstars") +
  theme_minimal()
```

![Local food restaurants inside the New Orleans city boundary, colored
by Yelp
stars.](yelp_new_orleans_project_files/figure-commonmark/unnamed-chunk-12-1.png)

Almost all the dots are packed into the bend of the river on the west
side: the French Quarter and CBD, then a thinner line going uptown. The
whole eastern half of the city, which is mostly New Orleans East and the
wetlands, has a handful.

## Step 6: choose and defend a geographic area

The question is “which part of the city”, so I need to cut the city into
parts. There is no one right way to do that. I compared three:

- **ZIP codes (ZCTAs)**, from the census. People know their ZIP code,
  but ZIPs were drawn for mail routes and some cover several very
  different neighborhoods.
- **Census tracts**, also from the census. Drawn to hold a few thousand
  people each, so they are small and even, but they only have numbers
  for names.
- **Neighborhood Statistical Areas (NSAs)**, from the City of New
  Orleans open data site. Named neighborhoods like French Quarter,
  Marigny, Bywater, Garden District.

``` r
zctas <- readRDS("data/boundaries/zctas_701.rds") |> st_transform(4326)
tracts <- readRDS("data/boundaries/orleans_tracts.rds") |> st_transform(4326)
neighborhoods <- readRDS("data/boundaries/neighborhoods.rds") |> st_transform(4326)

# the neighborhood file's name column
nsa_name_col <- intersect(c("gnocdc_lab", "GNOCDC_LAB", "neighborhood", "NEIGHBORHOOD", "name", "NAME"), names(neighborhoods))[1]
if (is.na(nsa_name_col)) nsa_name_col <- names(neighborhoods)[sapply(neighborhoods, is.character)][1]
neighborhoods <- neighborhoods |> rename(area_name = all_of(nsa_name_col))
# the file has the names in all caps
neighborhoods <- neighborhoods |> mutate(area_name = str_to_title(area_name))

# ZCTAs cover the suburbs too, keep only the ones that touch the city
zctas <- zctas |> filter(lengths(st_intersects(zctas, new_orleans_boundary)) > 0)

zctas <- zctas |> mutate(area_name = zcta) |> select(area_name)
tracts <- tracts |> mutate(area_name = paste("Tract", tract_name)) |> select(area_name)
neighborhoods <- neighborhoods |> select(area_name)

city_points <- restaurants_with_place |> filter(place_name == "New Orleans")
```

The same join for each system. For every restaurant inside the city,
find which area it is in, then count by area.

``` r
summarise_system <- function(points, areas, system_name) {
  joined <- points |>
    st_join(areas, join = st_within, left = TRUE) |>
    st_drop_geometry()

  per_area <- areas |>
    st_drop_geometry() |>
    left_join(
      joined |>
        filter(!is.na(area_name)) |>
        group_by(area_name) |>
        summarise(
          restaurants = n(),
          average_stars = mean(stars),
          reviews = sum(reviews_in_dataset),
          .groups = "drop"
        ),
      by = "area_name"
    ) |>
    mutate(restaurants = replace_na(restaurants, 0L), reviews = replace_na(reviews, 0L))

  tibble(
    system = system_name,
    areas = nrow(areas),
    restaurants_assigned = sum(!is.na(joined$area_name)),
    unmatched = sum(is.na(joined$area_name)),
    areas_with_none = sum(per_area$restaurants == 0),
    areas_with_5_or_more = sum(per_area$restaurants >= 5),
    smallest = min(per_area$restaurants),
    largest = max(per_area$restaurants),
    per_area = list(per_area)
  )
}

comparison <- bind_rows(
  summarise_system(city_points, zctas, "ZIP code (ZCTA)"),
  summarise_system(city_points, tracts, "Census tract"),
  summarise_system(city_points, neighborhoods, "Neighborhood (NSA)")
)

comparison |>
  select(-per_area) |>
  kable(col.names = c("Geographic system", "Areas", "Restaurants assigned", "Unmatched", "Areas with 0", "Areas with 5+", "Smallest", "Largest"))
```

| Geographic system | Areas | Restaurants assigned | Unmatched | Areas with 0 | Areas with 5+ | Smallest | Largest |
|:---|---:|---:|---:|---:|---:|---:|---:|
| ZIP code (ZCTA) | 21 | 632 | 0 | 4 | 16 | 0 | 212 |
| Census tract | 184 | 632 | 0 | 76 | 29 | 0 | 111 |
| Neighborhood (NSA) | 72 | 632 | 0 | 18 | 28 | 0 | 162 |

``` r
cmp <- comparison |> select(-per_area)
zip_row <- cmp |> filter(system == "ZIP code (ZCTA)")
tract_row <- cmp |> filter(system == "Census tract")
nsa_row <- cmp |> filter(system == "Neighborhood (NSA)")
```

### What the table says

ZIP codes: only 21 areas, and the biggest one has 212 restaurants. That
is too coarse. Telling someone “go to 70130” is not useful, that ZIP
covers the CBD, the Warehouse District and the Lower Garden District,
which are different places to eat.

Census tracts: 184 areas, so the opposite problem. 76 tracts have no
local food restaurant at all and only 29 have five or more. Most of the
comparisons would be between tracts with one or two restaurants, which
is noise. And nobody knows what “Tract 133” is.

Neighborhoods: 72 areas, 28 of them with five or more restaurants,
biggest one 162. The names mean something to a visitor and to anyone
from here. Unmatched points are 0, so the boundaries cover the city
fine.

``` r
count_maps <- bind_rows(
  zctas |> left_join(comparison$per_area[[1]], by = "area_name") |> mutate(system = "ZIP code (ZCTA)"),
  tracts |> left_join(comparison$per_area[[2]], by = "area_name") |> mutate(system = "Census tract"),
  neighborhoods |> left_join(comparison$per_area[[3]], by = "area_name") |> mutate(system = "Neighborhood (NSA)")
) |>
  mutate(
    restaurants = replace_na(restaurants, 0L),
    system = factor(system, levels = c("ZIP code (ZCTA)", "Census tract", "Neighborhood (NSA)"))
  )

bbox <- st_bbox(new_orleans_boundary)

ggplot(count_maps) +
  geom_sf(aes(fill = restaurants), color = "white", linewidth = 0.15) +
  geom_sf(data = new_orleans_boundary, fill = NA, color = "grey20", linewidth = 0.4) +
  scale_fill_viridis_c(trans = "sqrt", option = "D") +
  coord_sf(xlim = c(bbox["xmin"], bbox["xmax"]), ylim = c(bbox["ymin"], bbox["ymax"])) +
  facet_wrap(~system, nrow = 1) +
  labs(title = "Where the local food restaurants are, three ways to cut the city", fill = "Restaurants") +
  theme_minimal() +
  theme(axis.text = element_blank(), panel.grid = element_blank(), legend.position = "bottom", legend.key.width = unit(1.5, "cm"))
```

![Number of local food restaurants per area, under the three geographic
systems. Same color scale on all
three.](yelp_new_orleans_project_files/figure-commonmark/unnamed-chunk-16-1.png)

Same data, three pictures. The ZIP map is a few big blobs. The tract map
is a mosaic where most pieces are empty. The neighborhood map shows the
pattern at the scale people talk about: one bright strip along the river
from the French Quarter through the CBD and into the Lower Garden
District, fading out going uptown, and almost nothing east of the
Industrial Canal.

### My choice: Neighborhood Statistical Areas

I’m going with the neighborhoods for the main analysis. Reasons, in
order:

1.  They match the question. “Which part of the city” is a neighborhood
    question. A visitor asks “should I go to the Quarter or Uptown”, not
    “should I go to tract 133 or tract 137”.
2.  The areas are the right size. 28 neighborhoods have at least five
    restaurants, which is enough to compare averages without one
    restaurant swinging the whole area. ZIPs are too few and tracts are
    too many.
3.  The names are documented. The city publishes the boundaries and the
    names are the ones on neighborhood association signs and in local
    news.
4.  Nothing falls through. 0 restaurants inside the city are unmatched.

What the choice hides: a neighborhood like Uptown or the CBD is still
big enough that the best street inside it matters, and the map can’t
show that. Also a few neighborhoods have one or two restaurants and
their average rating will be unreliable. I flag those in the table below
and will leave them out of the final ranking.

The requirement was at least 10 restaurants in at least 7 different
areas. Under neighborhoods that is 54 areas with at least one restaurant
and 28 with five or more, so it clears easily.

### Neighborhoods ranked by local food restaurants

``` r
neighborhood_table <- comparison$per_area[[3]] |>
  filter(restaurants > 0) |>
  arrange(desc(restaurants)) |>
  mutate(average_stars = round(average_stars, 2))

neighborhood_table |>
  slice_head(n = 15) |>
  kable(col.names = c("Neighborhood", "Restaurants", "Average stars", "Reviews in dataset"))
```

| Neighborhood              | Restaurants | Average stars | Reviews in dataset |
|:--------------------------|------------:|--------------:|-------------------:|
| French Quarter            |         162 |          3.67 |              97219 |
| Central Business District |         115 |          3.71 |              59770 |
| Lower Garden District     |          37 |          3.77 |              14819 |
| Central City              |          34 |          3.90 |               7492 |
| Mid-City                  |          24 |          3.88 |               8289 |
| Marigny                   |          20 |          3.98 |               6151 |
| Leonidas                  |          17 |          4.00 |               5411 |
| Seventh Ward              |          12 |          4.29 |               1662 |
| East Riverside            |          11 |          3.82 |               6100 |
| Uptown                    |          11 |          4.09 |               2002 |
| Bywater                   |          11 |          4.09 |               4360 |
| Treme - Lafitte           |           9 |          4.17 |               5329 |
| Tulane - Gravier          |           9 |          3.78 |                833 |
| Touro                     |           8 |          3.81 |               2796 |
| Milan                     |           8 |          3.69 |                525 |

``` r
top_nb <- neighborhood_table |> slice_head(n = 3)
```

French Quarter has the most local food restaurants (162), then Central
Business District (115) and Lower Garden District (37). Count is not the
same as quality though. The next map shows the average Yelp rating by
neighborhood, only for neighborhoods with at least five restaurants so
one place can’t drive the color.

``` r
rating_map <- neighborhoods |>
  left_join(comparison$per_area[[3]], by = "area_name") |>
  mutate(average_stars_shown = if_else(restaurants >= 5, average_stars, NA_real_))

ggplot() +
  geom_sf(data = rating_map, aes(fill = average_stars_shown), color = "white", linewidth = 0.2) +
  geom_sf(data = new_orleans_boundary, fill = NA, color = "grey20", linewidth = 0.4) +
  scale_fill_viridis_c(option = "C", na.value = "grey88", limits = c(3, 5)) +
  coord_sf(xlim = c(bbox["xmin"], bbox["xmax"]), ylim = c(bbox["ymin"], bbox["ymax"])) +
  labs(title = "Average rating of local food restaurants by neighborhood", fill = "Average\nstars") +
  theme_minimal() +
  theme(axis.text = element_blank(), panel.grid = element_blank())
```

![Average Yelp stars of local food restaurants by neighborhood. Grey
neighborhoods have fewer than five
restaurants.](yelp_new_orleans_project_files/figure-commonmark/unnamed-chunk-19-1.png)

``` r
best_rated <- neighborhood_table |>
  filter(restaurants >= 5) |>
  arrange(desc(average_stars)) |>
  slice_head(n = 5)

kable(best_rated, col.names = c("Neighborhood", "Restaurants", "Average stars", "Reviews in dataset"))
```

| Neighborhood    | Restaurants | Average stars | Reviews in dataset |
|:----------------|------------:|--------------:|-------------------:|
| Freret          |           5 |          4.30 |               1047 |
| Seventh Ward    |          12 |          4.29 |               1662 |
| Treme - Lafitte |           9 |          4.17 |               5329 |
| Uptown          |          11 |          4.09 |               2002 |
| Bywater         |          11 |          4.09 |               4360 |

``` r
fq_stars <- neighborhood_table$average_stars[neighborhood_table$area_name == "French Quarter"]
fq_rank <- which(arrange(filter(neighborhood_table, restaurants >= 5), desc(average_stars))$area_name == "French Quarter")
```

Among neighborhoods with at least five local food restaurants, Freret
has the highest average at 4.3 stars, with only 5 restaurants, so one
new place could move it. Seventh Ward (12 restaurants) and Treme -
Lafitte (9) are right behind. The big purple block in the east is one
huge neighborhood with just enough restaurants to get a color, which
says more about how big the area is than about the food. The French
Quarter, with the most restaurants by far, is only number 23 of 28 at
3.67 stars. Tourist areas get a lot of reviews but not the best ones.

These are plain Yelp averages. Step 7 will redo this with reviewer
adjusted scores and check whether the ranking holds.
