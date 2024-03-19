DATA_DIR=$(readlink -f ./empiar10064.raw)
mkdir ${DATA_DIR}

wget -nH --cut-dirs=4 --progress=bar:force:noscroll -m -P ${DATA_DIR} ftp://ftp.ebi.ac.uk/empiar/world_availability/10064/data/mixedCTEM*.mrc
