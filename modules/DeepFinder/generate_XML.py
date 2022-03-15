import pandas as pd
import argparse

parser = argparse.ArgumentParser(
    description="Generate DeepFinder Object Lists from Dynamo Table"
)
parser.add_argument(
    "--tblpath",
    required=True,
    help="Absolute path to directory containing the Dynamo tbl files",
    action="store",
)
parser.add_argument(
    "--binning",
    required=False,
    help="binning level",
    action="store",
    default=1
)
# parser.add_argument(
#     "--outputname", required=True, help="Must be a .xml file", action="store",
# )
# parser.add_argument(
#     "--tbl", help="abolute path to the .tbl file", required=True, action="store"
# )

args = parser.parse_args()
tblpath = args.tblpath
# outputname = args.outputname
# tbl = args.tbl


def main(tblpath):
    concatenated_tbl = pd.read_table(tblpath, delimiter=" ", error_bad_lines=False,)
    new_column_names = [str(i) for i in range(1, 36)]
    concatenated_tbl.columns = new_column_names

    df = concatenated_tbl.rename(
        columns={
            "22": "class_label",
            "20": "tomo_idx",
            "24": "x",
            "25": "y",
            "26": "z",
            "4": "dx",
            "5": "dy",
            "6": "dz",
            "7": "phi",
            "8": "psi",
            "9": "the",
        }
    )
    ### TO DO jetzt für die einzelnen Tomos in der Liste einen separaten DF machen
    new_df = df
    ### df.drop_duplicates()

    distinct_tomos_by_id = new_df["tomo_idx"].drop_duplicates()
    distinct_tomos_by_list = sort(distinct_tomos_by_id.to_list())
    print(type(distinct_tomos_by_list))

    for i in range(length(distinct_tomos_by_list)):
        tomo_df = new_df[new_df["tomo_idx"] == distinct_tomos_by_list[i]]
        tomo_df["x"] = tomo_df["x"].div(args.binning) + tomo_df["dx"].div(args.binning) #.round(1)
        tomo_df["y"] = tomo_df["y"].div(args.binning) + tomo_df["dy"].div(args.binning) #.round(1)
        tomo_df["z"] = tomo_df["z"].div(args.binning) + tomo_df["dz"].div(args.binning) #.round(1)
        tomo_df["class_label"] = 1
        tomo_df["tomo_idx"] = i

        my_xml = tomo_df.to_xml(
            "tomogram_" + '{:03}'.format(i) + ".xml",
            index=False,
            root_name="objlist",
            row_name="object",
            attr_cols=["class_label", "phi", "psi", "the", "tomo_idx", "x", "y", "z",],
        )


if __name__ == "__main__":
    main(tblpath)

