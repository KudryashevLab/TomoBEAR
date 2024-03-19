DATA_DIR=$(readlink -f ./empiar10452.raw)
mkdir ${DATA_DIR}

for IDX in 01 10 14 20 38 39; do
    TOMO_IDX=tomo_${IDX}
    echo "================================"
    echo "Downloading data for ${TOMO_IDX}"
    wget -nH --cut-dirs=5 --progress=bar:force:noscroll -m -P ${DATA_DIR} ftp://ftp.ebi.ac.uk/empiar/world_availability/10452/data/${TOMO_IDX}.st ;
done
