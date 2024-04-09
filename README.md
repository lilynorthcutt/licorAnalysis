<!-- PROJECT LOGO AND INTRO SECTION -->
<br />
<div align="center">
  <a href="https://github.com/lilynorthcutt/licorAnalysis">
    <img src="img/cpi_img.png" alt="Logo" >
  </a>

  <h3 align="center">Analysis of Pepper SHU in Response to Stress</h3>

  <p align="center">
    This project is a part of the New Mexico State (NMSU) Chile Pepper Institute's (CPI) research program, and is        built in R to understand underlying relationships between stress and capsaicin content in New Mexico.
    <br />
    <br />
    <a href="https://cpi.nmsu.edu">CPI Homepage</a> 
    ·
    <a href="https://chilebreeding.nmsu.edu/index.html">Chile Breeding Program</a>
  </p>
  
</div>

<details >
<summary>__Table of Contents__</summary>

- [About The Project](#about-the-project)
- [Getting Started](#getting-started)
   * [Pre-Requisites](#pre-requisites)
   * [Installation Instructions](#installation-instructions)
- [Data](#data)
   * [Source Data](#source-data)
   * [Data Acquisition](#data-acquisition)
   * [Data Preprocessing](#data-preprocessing)
- [Code Structure](#code-structure)
- [Results and Eval](#results-and-eval)
- [Future Work](#future-work)
- [Acknowledgements/References](#acknowledgementsreferences)
- [License](#license)
</details>





<!-- About The Project -->
## About The Project

We are looking at plant porometry, fluorometry, plant yield/maturity, and environmental factor data to gain better insight into the scoville heat unit (SHU) in new mexican chile peppers. The goal is to understand how SHU is affected by looking at the following: 

* Environmental data such as weather and altitude
* The plants stress response (taken using LICOR LI600)
* The quality of yield - fruit weight, color, fruit maturity, yield quantity. 

Understanding these relationships will better aid farmers and researchers in all of their spicy endeavors, whether it be breeding the worlds hottest pepper, or simply maintaining a constant heat level in their harvest.




<!-- GETTING STARTED -->
## Getting Started

This project is fairly contained, with minimal setup. However, due to the proprietary nature of the data, the data is not stored on  github. The instructions for NMSU CPI researchers data access is described below.

### Pre-Requisites
The code is entirely based in R, using SQL to query environmental data.

- **Editor Used**: RStudio version 2023.12.1
- **R Version**: R version 4.3.3


### Installation Instructions
Below are the 

1. Clone the repo 

  ```bash
  git clone https://github.com/lilynorthcutt/licorAnalysis.git
  ```
2. Request access to the LICOR project through Dr. Dennis Lozada. 
3. Navigate to the files in the LICOR project and copy the `Data` folder
4. Paste the `Data` folder into the main directory of the project
<div align="center">
</br>
  <a href="https://github.com/lilynorthcutt/licorAnalysis">
      <img src="img/data_structure.png" alt="data_setup" width="400" height="250" >
  </a>
</div>

>:warning: **Do not change the file names within `Data`**: The code is dependent on the filenames remaining the same!

## Data
The LICOR data used in this project is proprietary and belongs to NMSU, if access is granted, researcher can follow the steps below to setup the project. 

### Source Data
Test

### Data Acquisition

### Data Preprocessing

## Code Structure

## Results and Eval

## Future Work

## Acknowledgements/References

## License

