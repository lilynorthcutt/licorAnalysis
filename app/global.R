setwd("..")
source("src/data/preprocess.R")

vars_to_keep <- c("rep","label23C","location","shu", "shuLabel", "date")
factors_list <- data %>% select(-all_of(vars_to_keep)) %>% unique() %>% colnames()
# label_key <- as.data.frame(
#   factor = c("gsw", "gbw", "gtw", "e_apparent", "v_pcham", "v_pref", "v_pleaf", "vp_dleaf",  
#              "h_2_o_r", "h_2_o_s", "h_2_o_leaf", "fs", "fm.1", "phi_ps_2", "etr", "rh_s",
#              "rh_r", "tref", "tleaf", "p_atm", "flow", "flow_s", "leak_pct", "qamb", "batt", 
#              "rh_adj", "gsw_1_sec", "gsw_2_sec", "gsw_4_sec", "flr_1_sec", "flr_2_sec",
#              "flr_4_sec", "v_hum_a", "v_hum_b", "v_flow_in", "v_flow_out", "v_temp",
#              "v_irt", "v_pres", "v_par", "v_f", "i_led"),
#   key = c("Stomatal Conductance", "One-sided boundary layer conductance",
#           "Total conductance", "Transpiration", "Chamber vapor pressure", 
#           "Reference vapor pressure", "Leaf vapor pressure", "Vapor pressure deficit",
#           "Reference H2O mole fraction", "Chamber H2O mole fraction", "Leaf H2O mole fraction",
#           "Leaf area in cm2", "Leaf width in mm", )
# )
