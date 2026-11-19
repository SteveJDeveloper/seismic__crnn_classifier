% Script para convertir un archivo .mat a JSON
% Cambia el nombre del archivo de entrada y salida según sea necesario

inputFile = '../data/raw/[NOMBRE_ARCHIVO].mat';
outputFile = '../data/interim/[NOMBRE_ARCHIVO].json';

data = load(inputFile);

% Convertir la estructura a JSON
jsonStr = jsonencode(data);

% Guardar el JSON en un archivo
fid = fopen(outputFile, 'w');
if fid == -1
    error('No se pudo abrir el archivo de salida.');
end
fwrite(fid, jsonStr, 'char');
fclose(fid);

disp(['Archivo JSON guardado en: ', outputFile]);
