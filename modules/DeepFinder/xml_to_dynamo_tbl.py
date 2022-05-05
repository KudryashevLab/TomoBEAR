import os
import glob
import pandas as pd
import numpy as np
from pandas.core.frame import DataFrame
import argparse
import locale

parser = argparse.ArgumentParser(
    description="Generate Dynamo Table from DeepFinder XML"
)
parser.add_argument(
    "--dirpath",
    required=True,
    help="Absolute/relative path to directory containing the XML files",
    action="store",
)
parser.add_argument(
    "--outputname", required=True, help="Must be a .tbl file", action="store",
)
parser.add_argument(
    "--tbl", help="abolute path to the .tbl file", required=True, action="store"
)

args = parser.parse_args()
dirpath = args.dirpath
outputname = args.outputname
tbl = args.tbl


def main(dirpath, tbl):
    xml_files = glob.glob(dirpath + '/tomogram_*_segmentation.xml')
    sorted_xml_files = sorted(xml_files)
    for i in sorted_xml_files:
        splitted_folders = i.split('/')
        splitted_name = splitted_folders[-1].split('_')
        df_xml = pd.read_xml(i)
        x_coordinates = df_xml["x"]
        y_coordinates = df_xml["y"]
        z_coordinates = df_xml["z"]
        cluster_size = df_xml["cluster_size"]
        number_of_particles_xml = len(df_xml)
        df_tbl = pd.read_table(tbl, delimiter=" ", error_bad_lines=False)
        df_tbl_column_names = [str(i) for i in range(1, 36)]
        df_tbl.columns = df_tbl_column_names
        df_tbl_tomo = df_tbl[df_tbl["20"] == int(splitted_name[1])]
        number_of_particles_tbl = len(df_tbl_tomo)
        difference_in_particles = number_of_particles_xml - number_of_particles_tbl
        all_zero = pd.DataFrame(np.zeros((difference_in_particles, 35)))
        all_zero.columns = df_tbl_column_names
        to_concat = [df_tbl_tomo, all_zero]
        extended_df = pd.concat(to_concat)
        extended_df = extended_df.set_index(df_xml.index)

        ymin = df_tbl_tomo.iloc[1]["14"]
        ymax = df_tbl_tomo.iloc[1]["15"]

        extended_df["2"] = 1
        extended_df["3"] = 1
        extended_df["4"] = 0
        extended_df["5"] = 0
        extended_df["6"] = 0
        extended_df["7"] = 0
        extended_df["8"] = 0
        extended_df["9"] = 0
        extended_df["10"] = 0
        extended_df["11"] = 0
        extended_df["12"] = 0
        extended_df["13"] = 1
        extended_df["14"] = ymin
        extended_df["15"] = ymax
        extended_df["16"] = ymin
        extended_df["17"] = ymax
        extended_df["18"] = 0
        extended_df["19"] = 0
        extended_df["20"] = int(splitted_name[1])
        extended_df["21"] = 0
        extended_df["22"] = df_xml["class_label"]
        extended_df["23"] = cluster_size
        extended_df["24"] = x_coordinates
        extended_df["25"] = y_coordinates
        extended_df["26"] = z_coordinates
        extended_df["27"] = 0
        extended_df["28"] = 0
        extended_df["29"] = 0
        extended_df["30"] = 0
        extended_df["31"] = 0
        extended_df["32"] = 1
        extended_df["33"] = 0
        extended_df["34"] = 1
        extended_df["35"] = 0

        extendend_df_no_nan = extended_df.replace(np.nan, 0)
        extendend_df_no_nan.to_csv(
            "tomogram_" + str(splitted_name[1]) + ".txt",
            sep=" ",
            float_format="%.3f",
            index=False,
            header=False,
        )


if __name__ == "__main__":
    locale.setlocale(locale.LC_ALL, 'en_US')
    main(dirpath, tbl)
    txt_files = glob.glob(dirpath + '/tomogram_*.txt')
    sorted_txt_files = sorted(txt_files)
    with open(outputname, "a+") as file_object:
        for j in sorted_txt_files:
            with open(j, "r") as single_file:
                file_object.write(single_file.read())
    concatenated_file = pd.read_csv(outputname, delimiter=" ")
    dimensions = concatenated_file.shape
    concatenated_file_column_names = [k for k in range(1, 36)]
    concatenated_file.columns = concatenated_file_column_names
    concatenated_file[1] = [i for i in range(1, dimensions[0] + 1)]
    concatenated_file.to_csv(
        outputname, sep=" ", float_format="%.3f", index=False, header=False,
    )

