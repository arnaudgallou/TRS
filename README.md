# Temperature range squeeze hypothesis

1. [Description](#description)
2. [Usage](#usage)
3. [Climate data](#climate-data)
4. [Dependencies](#dependencies)
4. [Disclaimer](#disclaimer)

## Description

Repository to reproduce the analyses in the paper "Diurnal temperature variation drives elevational range sizes globally".

## Usage

Simply use the `main.R` file to run all the analyses performed in the manuscript.

You can run multiple models automatically using a set of `for` loops or `map` functions. For example:

```
# global-scale analyses

for (expr in c(~dtr, ~ts, ~past_dmat)) {
  for (elevation_span in ELEV_SPANS) {
    for (exclusion_zone in EXCLS) {
      mdl_data <- compile_mdl_data(
        trs,
        clim_data = trs_bioclim,
        elevation_span = elevation_span,
        exclusion_zone = exclusion_zone,
        singleton_thr = SINGLETON_THR,
        std_elev_grad = TRUE,
        average = TRUE,
        std_from = "top",
        cols = c("location", "sp_range", "land_type"),
        expr = expr
      )
      
      run_jags(
        mdl_data,
        model = model,
        n.iter = JAGS_ITER,
        n.thin = JAGS_THIN,
        n.chains = JAGS_CHAINS,
        n.burnin = JAGS_BURN_IN,
        save = TRUE,
        path = glue("data/jags/{model$scope}-scale/")
      )
      
      gc() # to free up RAM
    }
  }
}
```

Note that the `expr` parameter in `compile_mdl_data()` takes a **formula** for the global-scale analyses and a **character string** for the local-scale analyses.

A list of the different models ran in the manuscript can be found [below](#models).

Once the models have finished running, use:

-   `results.R` to plot model estimates and get model statistics

-   `mdl_diagnostics.R` to perform model diagnostics

<a name="models" />

### Models

-   Global-scale analyses:

    -   main models: `~dtr`, `~ts`, `~past_dmat`
    -   land type: `~dtr * land_type`, `~ts * land_type`, `~past_dmat * land_type`
    -   climate-related interactions: `~dtr * ap`, `~dtr * mat`, `~past_dmat * past_map`

-   Local-scale analyses: `"dtr"`, `"ts"`

### Gilchrist analyses

Run the following line to make the required data set to reproduce the analyses on Gilchrist's hypothesis.

```
trs_dtr_lower_third <- filter(trs, bio2 <= max(trs$bio2, na.rm = TRUE) / 3)
```

Run the `~past_dmat` model using the `trs_dtr_lower_third` data set. I recommend changing the output `path` and `filename` in `run_jags()` to avoid overwriting existing output files. Finally, use `global_analyses()` to plot model estimates:

```
gilchrist <- global_analyses(path_to_gilchrist_outputs)

gilchrist$plot_regressions_(
  exclusion_zone = EXCL_DEFAULT,
  facet_by = "elevation_span",
  labellers = "∆ mean annual temperature (0-1980) (°C)"
)

gilchrist$plot_posterior_distributions_(
  exclusion_zone = EXCL_DEFAULT,
  yvar = "elevation_span",
  facet = FALSE,
  reverse = TRUE,
  scales = .6
)
```

## Climate data

Climate data are already provided in the `trs.csv` data set.

If you would like to perform GIS analyses again, proceed as follows:

1.  Open `TRS.Rproj` and execute the following function in the console: `TRS.utilities:::setup_gis()`. The function will create all the required directories to store SRTM and climate-related data.
2.  Download [bioclim](https://chelsa-climate.org/downloads/) and [digital elevation](https://earthexplorer.usgs.gov) data (as `.tif`) as well as [PaleoView](https://github.com/GlobalEcologyLab/PaleoView/releases). See [here](#paleoview) for instructions to generate past climate data.
3.  Save each file in the appropriate folder (see file tree below).
4.  Once all the files are in their respective folders, use the `gis.R` script to extract present and past climate data in each location. Output data will be stored in the `gis/clim/extracted/` subfolders.

```
gis
├── clim
│   ├── data
│   │   ├── past                        <- PaleoView-related folder
│   │   │   ├── base                    <- past climate data go here
│   │   │   └── var
│   │   │       ├── mean precipitation  <- generated mean precipitation files go here
│   │   │       └── mean temperature    <- generated mean temperature files go here
│   │   └── present                     <- present bioclim files go here
│   └── extracted
│       ├── past
│       └── present
└── srtm                                <- save each SRTM tile in the corresponding subfolders
    ├── Afghanistan
    ├── Alborz Mountains
    ├── Azores
    ├── Baekdudaegan Mountains
    ├── Bioko
    ├── Canary
    ├── Cantabria
    ├── Cape Verde
    ├── Chicauma
    ├── Colombian Andes
    ├── Crete
    ├── Cyprus
    ├── Denali
    ├── Drakensberg
    ├── Euboea
    ├── Golestan
    ├── Hawaii
    ├── Hengduan
    ├── Jamaica
    ├── Jaya
    ├── Kenya
    ├── La Amistad
    ├── Lazio
    ├── Mt Ararat
    ├── Mt Etna
    ├── Mt Kilimanjaro
    ├── Nanga Parbat
    ├── Nepal
    ├── Nevada Test Site
    ├── Owens Peak
    ├── Reunion
    ├── Santa Rosa Mountains
    ├── Sierra Nevada
    ├── Sierra San Pedro Martir
    ├── Socotra
    ├── South-Eastern Pyrenees
    ├── Swiss Alps
    ├── Tahoe
    ├── Taiwan
    ├── Tajikistan
    ├── Tasmania
    ├── Utah
    ├── Venezuelan Andes
    └── Wind River Mountains
```

<a name="paleoview" />

### Generating past climate data

Open PaleoView and download the climate data (see chapter 2 of [PaleoView's user manual](http://www.ecography.org/sites/ecography.org/files/appendix/ecog-03031.pdf)) for mean temperature and precipitation. Configure the input data location (see chapter 3 in the user manual). Run PaleoView with the same settings as shown in the image below for `temperature` and `precipitation`:  

<img src="images/paleoview_settings.png" style="heigh: 639px; width: 556px"/></img>

## Dependencies

Below is the list of the different `R` packages required to run the code in this reposity:

- `tidyverse`

- `TRS.utilities`

- `glue`

- `bayesplot` (only for model diagnostics)

To install the `TRS.utilities` package, use:

```
devtools::install_github("arnaudgallou/TRS.utilities")
```

In addition, you will need to have [JAGS](https://sourceforge.net/projects/mcmc-jags/) installed on your system.

## Disclaimer

The `TRS.utilities` package was designed specifically for this project. Many of the functions contained in the package might not be reusable in your own application.
