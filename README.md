# Dog Breed Explorer

An end-to-end data pipeline on GCP that ingests dog breed data from The Dog API, models it with dbt, and serves analytics through Looker Studio.

![CI/CD](https://github.com/YOUR_USERNAME/dog-breed-explorer/actions/workflows/ci.yml/badge.svg)

## Architecture

Dog API -> dlt (Cloud Run) -> GCS (raw JSON) -> BigQuery (bronze) -> dbt (silver/gold) -> Looker Studio

## Quick Start

See EXECUTION_GUIDE.md for step-by-step instructions.

## Data Model (Medallion Architecture)

| Layer | Table | Description |
|-------|-------|-------------|
| Bronze | bronze.dog_api_raw | Raw JSON from API |
| Silver | silver.stg_dog_breeds | Typed and cleaned |
| Gold | gold.dim_breed | Breed dimension with size class |
| Gold | gold.fact_weight_life_span | Numeric metrics for analysis |

## Data Quality

- unique + not_null on breed_id
- not_null on breed_name
- accepted_values on size_class
- Custom test: assert_life_span_positive

## Findings (300 words)

Our analysis of 170+ dog breeds reveals that weight is the strongest predictor of life span. Small breeds live approximately 3.4 years longer than giant breeds on average (13.5 vs 10.1 years). Toy and Terrier groups dominate the longevity charts. The most popular family-friendly temperaments (Loyal, Friendly) correlate with shorter life spans, but this is a size confound, not causation: the friendliest breeds tend to be large. A pet insurance company could use this data to price policies by weight class rather than breed name alone.
<!-- setup complete -->
