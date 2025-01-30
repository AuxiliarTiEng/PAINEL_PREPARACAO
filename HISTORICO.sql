WITH months AS (
    SELECT ADD_MONTHS(TRUNC(SYSDATE, 'mm'), LEVEL - 24) AS month_start,
           ADD_MONTHS(TRUNC(SYSDATE, 'mm'), LEVEL - 23) - 1 AS month_end
    FROM DUAL
    CONNECT BY LEVEL <=24 
),
precomputed as
(SELECT max(odv.chassi) chassi_his,nvl(odv.placa,odv.chassi) AS PLACA_HIS,max(odv.cor_externa) cor_his,max(pm.DESCRICAO_MODELO || ' - ' || pm.ANO_MODELO) modelo_his,max(trunc(vk.data,'dd')) entrada_his,
       CEIL(MAX(os.DATA_ENCERRADA)  -  MAX(TRUNC(vk."DATA",'dd'))) AS DPT_HIS,
       to_char(TRUNC(m.month_start, 'MM'),'MM') AS MES_HIS,to_char(TRUNC(m.month_start, 'MM'),'YYYY') AS ANO_HIS,max(os.data_prometida) prometida_his,
       trunc(MAX(TO_DATE(TO_CHAR(os.DATA_ENCERRADA, 'YYYY-MM-DD') || ' ' || os.HORA_ENCERRADA,'YYYY-MM-DD HH24:MI:SS' )),'dd') encerramento_his
FROM months m
inner JOIN OS os
    ON os.DATA_ENCERRADA BETWEEN m.month_start AND m.month_end 
INNER JOIN OS_DADOS_VEICULOS odv
    ON os.COD_EMPRESA = odv.COD_EMPRESA AND os.NUMERO_OS = odv.NUMERO_OS
INNER JOIN VEIC_KARDEX vk
    ON vk.CHASSI_COMPLETO IN odv.CHASSI AND vk.COD_OPERACAO IN (1, 7) and vk.data <= TO_DATE(TO_CHAR(os.DATA_ENCERRADA, 'YYYY-MM-DD') || ' ' || os.HORA_ENCERRADA, 'YYYY-MM-DD HH24:MI:SS')
INNER JOIN PRODUTOS_MODELOS pm on pm.COD_MODELO = odv.COD_MODELO  AND pm.COD_PRODUTO = odv.COD_PRODUTO 
WHERE os.tipo IN ('IU', 'RU','EU') 

  AND os.COD_EMPRESA = '12' 
  AND os.STATUS_OS = 1
  AND (SELECT vh.cod_patio 
       FROM vw_bi_veiculos_historico vh 
       WHERE SUBSTR(odv.chassi, -7, 7) = vh.chassi_resumido
         AND vh.DATA <= TO_DATE(TO_CHAR(os.DATA_ENCERRADA, 'YYYY-MM-DD') || ' ' || os.HORA_ENCERRADA, 'YYYY-MM-DD HH24:MI:SS')
         AND ROWNUM = 1) IN (21, 5)
  AND (SELECT COUNT(*) 
       FROM OS os2
       INNER JOIN OS_DADOS_VEICULOS odv2 
           ON os2.COD_EMPRESA = odv2.COD_EMPRESA AND os2.NUMERO_OS = odv2.NUMERO_OS 
       WHERE os2.COD_EMPRESA = os.COD_EMPRESA
         AND odv.CHASSI = odv2.CHASSI
         AND os2.STATUS_OS = 0
         AND os2.tipo IN ('IU', 'RU','EU')) = 0
GROUP BY nvl(odv.placa,odv.chassi), TRUNC(m.month_start, 'MM'),m.month_end

ORDER BY TRUNC(m.month_start, 'MM'), nvl(odv.placa,odv.chassi))
select chassi_his, DECODE(INSTR(placa_his, '-'),0, SUBSTR(placa_his, 1, 3)||'-'||SUBSTR(placa_his, 4, 4) ,placa_his) placa_his,cor_his,modelo_his,entrada_his,encerramento_his,dpt_his,ano_his || '/' ||MES_his ANOMES_HIS,prometida_his,
(SELECT MIN(OS.DATA_EMISSAO) 
               FROM OS os
               INNER JOIN OS_DADOS_VEICULOS odv ON os.numero_os = odv.numero_os and os.cod_empresa = odv.cod_empresa
               WHERE odv.CHASSI = pc.CHASSI_his 
               AND os.DATA_EMISSAO between pc.entrada_his and pc.encerramento_his
               AND os.tipo IN ('IU', 'RU', 'EU')
               AND os.ORCAMENTO <> 'S'
               AND OS.COD_EMPRESA = 12
               AND OS.STATUS_OS <> 2) "ABERTURA_OS_HIS",
nvl((SELECT SUM( greatest(0,(nvl(OS.valor_servicos_bruto,0) + nvl(OS.valor_itens_bruto,0)) -
                       (nvl(decode(os.tem_desconto_item,'S', nvl(OS.valor_desconto_item, OS.descontos_itens)
             , OS.descontos_itens),0) + nvl(OS.descontos_servicos,0)))) 
              FROM OS
              INNER JOIN OS_DADOS_VEICULOS odv ON os.numero_os = odv.numero_os and os.cod_empresa = odv.cod_empresa
              WHERE odv.CHASSI = pc.CHASSI_his 
                AND os.DATA_EMISSAO between pc.entrada_his and pc.encerramento_his
                AND os.tipo IN ('IU', 'RU', 'EU')
                AND os.ORCAMENTO <> 'S'
                AND OS.COD_EMPRESA = 12
                AND OS.STATUS_OS <> 2),0) CUSTO_HIS,
      CASE 
        WHEN (SELECT COUNT(*) 
              FROM OS
              INNER JOIN OS_DADOS_VEICULOS odv ON os.numero_os = odv.numero_os
              WHERE odv.CHASSI = pc.CHASSI_his 
                AND os.DATA_EMISSAO between pc.entrada_his and pc.encerramento_his
                AND os.tipo IN ('RU')
                AND os.ORCAMENTO <> 'S' 
                AND OS.COD_EMPRESA = 12
                AND OS.STATUS_OS <> 2) > 0 
        THEN 'S' 
        ELSE 'N' 
    END POSSUI_RETORNO_his
from precomputed pc;
