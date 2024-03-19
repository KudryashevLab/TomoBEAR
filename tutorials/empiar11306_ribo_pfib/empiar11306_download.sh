DATA_DIR=$(readlink -f ./empiar11306.raw)
mkdir ${DATA_DIR}

echo "Downloading gain reference..."
wget -nH --cut-dirs=7 --progress=bar:force:noscroll -m -P ${DATA_DIR} ftp://ftp.ebi.ac.uk/empiar/world_availability/11306/data/HeLa_argon/gain_ref/*_EER_GainReference.gain* ;

for IDX in 146 147 148 149 158; do
    TOMO_IDX=Position_${IDX}
    echo "================================"
    echo "Downloading data for ${TOMO_IDX}"
    wget -nH --cut-dirs=6 --progress=bar:force:noscroll -m -P ${DATA_DIR} ftp://ftp.ebi.ac.uk/empiar/world_availability/11306/data/HeLa_argon/${TOMO_IDX}*_EER.eer ;
done
