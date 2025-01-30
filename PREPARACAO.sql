SELECT DECODE(v.COD_PATIO,5,'Oficina 3°','CD Curado') PATIO,v.CHASSI_COMPLETO,
              
              (SELECT MIN(OS.DATA_EMISSAO) 
               FROM OS os
               INNER JOIN OS_DADOS_VEICULOS odv ON os.numero_os = odv.numero_os and os.cod_empresa = odv.cod_empresa
               WHERE odv.CHASSI = v.CHASSI_COMPLETO 
               AND os.DATA_EMISSAO > v.DATA_NOTA 
               AND os.tipo IN ('IU', 'RU', 'EU')
               AND os.ORCAMENTO <> 'S'
               AND OS.COD_EMPRESA = 12
               AND OS.STATUS_OS <> 2) "Data Abertura OS",
              
              (SELECT greatest(NVL(MAX(OS.DATA_EMISSAO),'01/01/1900'),NVL(MAX(os.data_prometida),'01/01/1900'),NVL(MAX(OS.DATA_ENCERRADA),'01/01/1900')) 
               FROM OS os
               INNER JOIN OS_DADOS_VEICULOS odv ON os.numero_os = odv.numero_os and os.cod_empresa = odv.cod_empresa
               WHERE odv.CHASSI = v.CHASSI_COMPLETO 
               AND os.DATA_EMISSAO > v.DATA_NOTA 
               AND os.tipo IN ('IU', 'RU','EU')
               AND os.ORCAMENTO <> 'S'
               AND OS.COD_EMPRESA = 12
               AND OS.STATUS_OS <> 2) "Data Previsão OS",
                decode((SELECT count(*)
                   FROM OS
                   INNER JOIN OS_DADOS_VEICULOS ODV ON OS.NUMERO_OS = ODV.NUMERO_OS AND OS.COD_EMPRESA = ODV.COD_EMPRESA
                   WHERE ODV.CHASSI = V.CHASSI_COMPLETO
                   AND OS.DATA_EMISSAO > V.DATA_NOTA
                   AND OS.TIPO IN ('IU', 'RU', 'EU')
                   AND OS.ORCAMENTO <> 'S'
                   AND OS.COD_EMPRESA = 12
                   and os.status_os = 0),0,
                   (SELECT max(os.data_encerrada)
                   FROM OS
                   INNER JOIN OS_DADOS_VEICULOS ODV ON OS.NUMERO_OS = ODV.NUMERO_OS AND OS.COD_EMPRESA = ODV.COD_EMPRESA
                   WHERE ODV.CHASSI = V.CHASSI_COMPLETO
                   AND OS.DATA_EMISSAO > V.DATA_NOTA
                   AND OS.TIPO IN ('IU', 'RU', 'EU')
                   AND OS.ORCAMENTO <> 'S'
                   AND OS.COD_EMPRESA = 12
                   and os.status_os = 1),null) "Encerramento Preparacao",
                  
                pm.DESCRICAO_MODELO || ' - ' || pm.ANO_MODELO modelo, DECODE(INSTR(v.placa_usado, '-'),0,
                SUBSTR(v.placa_usado, 1, 3)||'-'||SUBSTR(v.placa_usado, 4, 4)
                ,V.PLACA_USADO) PLACA_USADO,ce.descricao COR_EXTERNA,
v.RESERVADO, ROUND(SYSDATE - v.DATA_NOTA) AS DPT,v.DATA_NOTA DATA_ENTRADA,
 CASE 
        WHEN (SELECT COUNT(*) 
              FROM OS
              INNER JOIN OS_DADOS_VEICULOS odv ON os.numero_os = odv.numero_os
              WHERE odv.CHASSI = v.CHASSI_COMPLETO 
                AND os.DATA_EMISSAO > v.DATA_NOTA 
                AND os.tipo IN ('IU', 'RU', 'EU')
                AND os.ORCAMENTO <> 'S' 
                AND OS.COD_EMPRESA = 12
                AND OS.STATUS_OS <> 2) > 0 
        THEN 'S' 
        ELSE 'N' 
    END POSSUI_Os,
    CASE 
        WHEN (SELECT COUNT(*) 
              FROM OS
              INNER JOIN OS_DADOS_VEICULOS odv ON os.numero_os = odv.numero_os
              WHERE odv.CHASSI = v.CHASSI_COMPLETO 
                AND os.DATA_EMISSAO > v.DATA_NOTA 
                AND os.tipo IN ('RU')
                AND os.ORCAMENTO <> 'S' 
                AND OS.COD_EMPRESA = 12
                AND OS.STATUS_OS <> 2) > 0 
        THEN 'S' 
        ELSE 'N' 
    END POSSUI_RETORNO,
    nvl((SELECT SUM( greatest(0,(nvl(OS.valor_servicos_bruto,0) + nvl(OS.valor_itens_bruto,0)) -
                       (nvl(decode(os.tem_desconto_item,'S', nvl(OS.valor_desconto_item, OS.descontos_itens)
             , OS.descontos_itens),0) + nvl(OS.descontos_servicos,0)))) 
              FROM OS
              INNER JOIN OS_DADOS_VEICULOS odv ON os.numero_os = odv.numero_os and os.cod_empresa = odv.cod_empresa
              WHERE odv.CHASSI = v.CHASSI_COMPLETO 
                AND os.DATA_EMISSAO > v.DATA_NOTA 
                AND os.tipo IN ('IU', 'RU', 'EU')
                AND os.ORCAMENTO <> 'S'
                AND OS.COD_EMPRESA = 12
                AND OS.STATUS_OS <> 2),0) CUSTO
FROM veiculos v 
INNER JOIN PRODUTOS_MODELOS pm on pm.COD_MODELO = v.COD_MODELO  AND pm.COD_PRODUTO = v.COD_PRODUTO 
INNER JOIN CORES_EXTERNAS ce ON ce.COR_EXTERNA = v.COR_EXTERNA 
WHERE  v.NOVO_USADO ='U' AND  v.status = 'E' AND v.COD_PATIO IN (21,5);
