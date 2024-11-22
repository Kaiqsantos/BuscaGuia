import os
from bs4 import BeautifulSoup
import requests
import pandas as pd
from io import StringIO
import re


def formatar(texto,ct=34, cf=49, est= (1,3)):
    print(f"\033[{ct};{cf};{';'.join(map(str, est))}m{texto}\033[0m")


def adicionar(exceto=None):
    if exceto is None:
        exceto = []
    exceto = [e.lower() for e in exceto]
    with open('../ultimo.properties', 'r+', encoding='utf-8') as arquivo:
        arq = arquivo.read().splitlines()
        arquivo.seek(0)
        arquivo.truncate()
        for esc in (lin.split('=') for lin in arq):
            if esc[0] not in exceto:
                arquivo.write(f"{esc[0]}={int(esc[1])+1}")


def baixar_guia(nome, numeros, exceto=None):
    if exceto is None:
        exceto = []
    exceto = [e.lower() for e in exceto]
    numeros = [numeros] if isinstance(numeros, int) else numeros
    os.makedirs(fr'arquivos_csv/{nome.upper()}',exist_ok=True)
    for x in numeros:
        if f"{nome}_{x}" in exceto or nome in exceto:
            continue
        url = fr'https://supac.ufba.br/sites/supac.ufba.br/files/{nome}_{x}.html'
        print(f"{nome}_{x}")
        resposta = requests.get(url)
        if resposta.status_code == 200:
            soup = BeautifulSoup(resposta.text, 'html.parser')
            sem = soup.select_one('html > body > p > th > font')
            if not sem:
                sem = soup.select_one('html > body > p > font')
            sem = str(sem).split('<br/>')[0].split(' ')[-1]
            table = soup.find('table')
            a = str(table).split('<tr>')
            b = a[-1].split('</tr>')
            c = [a[0]] + [f'<tr>{d[0].replace("\r", "").replace("\n", "") + d[1]}</tr>'
                          for d in zip(a[1:-1], reversed(b[1:-1]))] + [f'<tr>{b[0]}</tr>']
            tabela = ''.join(c + [b[-1]])
            df = pd.read_html(StringIO(tabela))[0]
            if len(df) == 1:
                df = pd.read_html(StringIO(str(table)))[0]
            df.to_csv(fr'arquivos_csv/{nome.upper()}/{nome}_{x:03d}_({sem}).csv', index=False)


def baixar(todos=False, exceto=None):
    unidade = dict(l.rstrip().split('=') for l in open('../ultimo.properties', 'r', encoding='utf-8'))
    for x in unidade.items():
        baixar_guia(x[0], range(1, int(x[1]) + 1) if todos else int(x[1]), exceto)


def pesquisa(item: str, unidade=None, busca="ultima", tipo="código", aviso=(False, False), formatado=True,
             fore=34, back=49, estilo=(1,3), multi=None, retornar=False, tabela=False, ocultar=(False,) * 10):
    pd.set_option("expand_frame_repr", False)

    busca = busca.lower()
    item = item.upper()
    tipo = tipo.lower()

    dias = {"SEG": "Segunda", "TER": "Terça", "QUA": "Quarta", "QUI": "Quinta",
            "SEX": "Sexta", "SAB": "Sábado", "DOM": "Domingo", "CMB": "A Combinar"}

    if not unidade:
        if tipo == "código":
            unidade = [item[0:3]]
        else:
            unidade = os.listdir("arquivos_csv")
    else:
        unidade = [unidade.upper()]

    nomes = dict(l.rstrip().split('=') for l in open('../cursos.properties', 'r', encoding='utf-8'))
    unidades = dict(l.rstrip().split('=') for l in open('../unidades.properties', 'r', encoding='utf-8'))

    def frm(obj, fb=fore, bb=back, est=estilo):
        if formatado:
            return f"\033[{fb};{bb};{';'.join(map(str, est))}m{obj}\033[0m"
        else:
            return obj

    def defcor(vt): return list(range(31,38)) + list(range(90,97))[vt[multi]] if multi else fore

    def filtro(dataf: pd.DataFrame, coluna: str, valor, i=-1):
        colu = dataf[coluna]
        if i == -1:
            ind_0 = dataf.index[colu == valor][0]
            ind_1 = dataf.iloc[ind_0 + 1:][coluna].first_valid_index()
            return dataf.iloc[ind_0:ind_1].copy().reset_index(drop=True)
        else:
            colu = colu.str.upper()
            ind_0 = colu[(colu == valor) & (colu.shift(fill_value='') != valor)].index[i]
            ind_1 = colu[(colu == valor) & (colu.shift(-1, fill_value='') != valor)].index[i]
            ind_2 = dataf.iloc[:ind_0+1, 1].last_valid_index()
            ind_3 = dataf.iloc[ind_1 + 1:, 1].first_valid_index() or (ind_2 + 1)
            dataf_2 = dataf.loc[ind_2:ind_3 - 1]
            dataf_2.iloc[0, 7:9] = dataf.iloc[dataf.iloc[:ind_2+1, 8].last_valid_index(),7:9]
            return dataf_2.reset_index(drop=True)

    def juntar(lista):
        return f'{", ".join(lista[:-1])} e {lista[-1]}' if len(lista) > 1 else lista[0]


    if any([v_unidade not in os.listdir("arquivos_csv") for v_unidade in unidade]):
        raise ValueError('Parâmetro "unidade" inválido.')
    if busca not in ["semestre", "todas", "ultima"] and not re.fullmatch(r'\d{4}-\d', busca):
        raise ValueError('Parâmetro "busca" inválido.')
    if tipo not in ["código", "matéria", "docente"]:
        raise ValueError('Parâmetro "tipo" inválido.')

    retornos = []
    for uni in unidade:
        procura = os.listdir(f"arquivos_csv/{uni}")
        if busca == "semestre":
            procura = procura[-1]
        elif re.fullmatch(r'\d{4}-\d', busca):
            procura = [ldir for ldir in reversed(procura) if busca in ldir]
        else:
            procura = reversed(procura)

        for proc in procura:
            df = pd.read_csv(f"arquivos_csv/{uni}/{proc}")
            if df.isnull().all(axis=1).all():
                continue

            df[['Código', 'Matéria']] = df['Disciplina'].str.split(' - ',n=1,expand=True)
            if item in df[tipo.capitalize()].str.upper().values:
                retorno = None
            else:
                if tipo == "código":
                    retorno = (f"A matéria de código {item} não foi encontrada no guia de matrícula Nº "
                               f"{int(proc[4:7])} da unidade {uni}")
                elif tipo == "matéria":
                    retorno = (f"A matéria {item} não foi encontrada no guia de matrícula Nº "
                               f"{int(proc[4:7])} da unidade {uni}")
                else:
                    retorno = (f"O docente {item} não foi encontrado no guia de matrícula Nº "
                               f"{int(proc[4:7])} da unidade {uni}")

            if retorno:
                if aviso[0]:
                    print(retorno)
                if aviso[1]:
                    retornos.append(retorno)
                continue

            df = df.dropna(how='all').reset_index(drop=True)

            bsc = tipo.capitalize()
            if bsc != "Docente":
                it = [-1]
            else:
                it = range(len(df[(df['Docente'].str.upper() == item) & (
                        df['Docente'].shift(-1, fill_value='').str.upper() != item)]))

            for ite in it:
                ndf_1 = filtro(df, bsc, item, ite)

                ndf_1['Turma'] = ndf_1['Turma'].astype(object)
                ndf_1['Turma'] = ndf_1['Turma'].apply(lambda x: None if pd.isna(x) else str(int(x)).zfill(6))
                it_tms = ndf_1['Turma'].dropna().reset_index(drop=True)

                tms = [frm(tm, fb=defcor([(i % 4) + 1, 2]), bb=back, est=estilo) for i, tm in enumerate(it_tms)]

                resp = {
                    'codigo': ndf_1['Código'].iloc[0],
                    'materia': ndf_1['Matéria'].iloc[0],
                    'semestre': proc[9:15],
                    'guia': str(int(proc[4:7])),
                    'turmas': tms,
                    'unidade': f'({uni}) {unidades[uni.lower()]}',
                    'plural_1': "a turma" if len(it_tms) == 1 else "as turmas"}
                if tabela:
                    dfr = ndf_1.fillna('').iloc[:,[not(ocultar[0] and ocultar[1]),
                                                                              not(ocultar[5]),
                                                                              not(ocultar[6]),
                                                                              not(ocultar[7]),
                                                                              not(ocultar[8]),
                                                                              not(ocultar[8]),
                                                                              not(ocultar[9]),
                                                                              False, False]]
                    if not retornar:
                        print(f"{'' if ocultar[3] else 'No guia de matrícula Nº ' + resp['guia']} "
                              f"{'' if ocultar[2] else '(' + resp['semestre'] + ')'} "
                              f"{'' if ocultar[4] else 'da unidade: ' + resp['unidade']} \n{dfr}")
                    retornos.append(dfr)
                    break
                for turm in range(len(resp['turmas'])):
                    resp[f'turma_{turm}'] = it_tms[turm]
                    ndf_2 = filtro(ndf_1, "Turma", it_tms[turm])
                    ndf_2 = ndf_2.dropna(how='all').reset_index(drop=True)
                    cursos = ndf_2['Coleg.'].dropna().unique().astype(int).astype(str)
                    vagas = ndf_2.iloc[ndf_2['Coleg.'].dropna().drop_duplicates().index, 2:4]
                    resp[f'plural_{turm}_2'] = "o curso" if len(cursos) == 1 else "os cursos"

                    tyc = [frm(f"{it_tyc} - {nomes[str(int(it_tyc))]
                           if str(int(it_tyc)) in nomes.keys() else 'NA'}", fb=defcor([turm % 4 + 1, 4]), bb=back,
                               est=estilo)
                           for it_tyc in cursos]
                    resp[f'turma_{turm}_cursos'] = tyc

                    if len(vagas) == 1:
                        vgs = (f"{'*' if ocultar[7] else frm(str(int(vagas.iloc[0, 1])), fb=defcor([turm % 4 + 1, 13]),
                                                             bb=back, est=estilo)}"
                               f"{' vaga' if vagas.iloc[0, 1] == 1 else ' vagas'}")
                    else:
                        vgs = juntar([(f"{'*' if ocultar[7] else frm(str(int(vagas.iloc[i, 1])),
                                                                     fb=defcor([turm % 4 + 1, 13]), bb=back,
                                                                     est=estilo)} "
                                       f"{'vaga para' if int(vagas.iloc[i, 1]) == 1 else 'vagas para'} "
                                       f"{'*' if ocultar[5] else frm(f'{str(int(vagas.iloc[i, 0]))} - '
                                                                     f'{nomes[str(int(vagas.iloc[i, 0]))] 
                                       if str(int(vagas.iloc[i, 0])) in nomes.keys() else "NA"}', 
                                              fb=defcor([turm % 4 + 1, 2]), bb=back, est=estilo)}")
                                      for i in range(len(vagas))])
                    resp[f'vagas_{turm}'] = vgs

                    doc = [frm(it_doc, fb=defcor([turm % 4 + 1, 10]), bb=back, est=estilo)
                           for it_doc in ndf_2['Docente'].dropna().unique()]
                    resp[f'docentes_{turm}'] = doc
                    horas = ndf_2[['Dia', 'Horário']].dropna(how='all').reset_index(drop=True)
                    horas['Dia'] = horas['Dia'].ffill()
                    splt = horas.groupby('Dia')['Horário'].apply(list).to_dict()
                    splt = {k: splt[k] for k in sorted(splt.keys(), key=lambda x: list(dias.keys()).index(x))}

                    hrs = [
                        (f"{frm(dias[it_splt], fb=defcor([turm % 4 + 1, 12]), bb=back, est=estilo)} de "
                         f"{juntar([frm(it_jnt, fb=defcor([turm % 4 + 1, 12]),
                                        bb=back, est=estilo) for it_jnt in splt[it_splt]])}")
                        for it_splt in splt
                    ]

                    resp[f'horarios_{turm}'] = hrs
                    resp[f'plural_{turm}_3'] = "o horário" if len(splt) == 1 else "os horários"
                    resp[f'plural_{turm}_4'] = "docente responsável" if len(doc) == 1 else "docentes responsáveis"

                    if len(doc) > 1:
                        jstrdoc = []
                        for it_hdoc in ndf_2['Docente'].dropna().unique():
                            hdoc = ndf_2[ndf_2['Dia'].notna() | ndf_2['Horário'].notna()][['Dia', 'Horário', 'Docente']]
                            hdoc['Dia'] = hdoc['Dia'].ffill()
                            hdoc = hdoc[hdoc['Docente'] == it_hdoc]
                            hspl = hdoc.groupby('Dia')['Horário'].apply(list).to_dict()
                            hspl = {k: hspl[k] for k in sorted(hspl, key=lambda x: list(dias.keys()).index(x))}
                            hrdoc = []
                            for it_hspl in hspl:
                                hdjnt = [frm(it_hdjnt, fb=defcor([turm % 4 + 1, 12]),
                                             bb=back, est=estilo) for it_hdjnt in hspl[it_hspl]]
                                hrdoc.append(
                                    '*' if ocultar[8] else f"{frm(dias[it_hspl], fb=defcor([turm % 4 + 1, 12]),
                                                                  bb=back, est=estilo)} de {juntar(hdjnt)}")

                            strdoc = ((f"{'*' if ocultar[9] else frm(it_hdoc, fb=defcor([turm % 4 + 1, 10]),
                                                                     bb=back, est=estilo)} responsável por ministrar "
                                      f"a disciplina durante ") +
                                      ("o horário:" if len(hspl) == 1 else "os horários:") + " " + ", ".join(hrdoc))

                            jstrdoc.append(strdoc)

                        horadoc = ", sendo: " + juntar(jstrdoc) + "."
                    else:
                        horadoc = "."
                    resp[f'horadocentes_{turm}'] = horadoc

                string = []
                nturmas = len(resp["turmas"])
                for it_t in range(nturmas):
                    string.append(f"{' '.join(['a turma',
                                               '*' if ocultar[5] else frm(resp[f'turma_{it_t}'],
                                                                          fb=defcor([it_t % 4 + 1, 3]),
                                                                          bb=back, est=estilo),
                                               ''])
                    if nturmas > 1 else ''}foi ofertada para {resp[f'plural_{it_t}_2']}: "
                    f"{'*' if ocultar[6] else juntar(resp[f'turma_{it_t}_cursos'])}, com {resp[f'vagas_{it_t}']} com "
                    f"{resp[f'plural_{it_t}_3']}: {'*' if ocultar[8] else juntar(resp[f'horarios_{it_t}'])} e: "
                    f"{'*' if ocultar[9] else juntar(resp[f'docentes_{it_t}'])} como {resp[f'plural_{it_t}_4']} "
                    f"por ministrar a disciplina{resp[f'horadocentes_{it_t}']}")
                retorno = (f"A matéria de código {'*' if ocultar[0] else frm(resp['codigo'],
                                                                             fb=91 if multi else fore,
                                                                             bb=back, est=estilo)}"
                           f" com o nome "
                           f"{'*' if ocultar[1] else frm(resp['materia'], fb=91 if multi else fore,
                                                         bb=back, est=estilo)}"
                           f" foi ofertada no semestre "
                           f"{'*' if ocultar[2] else frm(resp['semestre'], fb=91 if multi else fore,
                                                        bb=back, est=estilo)}"
                           f" conforme guia de matrícula Nº "
                           f"{'*' if ocultar[3] else frm(resp['guia'], fb=91 if multi else fore, bb=back, est=estilo)} "
                           f"da Unidade: {'*' if ocultar[4] else frm(resp['unidade'], fb=91 if multi else fore,
                                                                     bb=back, est=estilo)}, "
                           f"com {resp['plural_1']} {'*' if ocultar[5] else juntar(resp['turmas'])}, "
                           f"{'em ' if len(resp['turmas'])>1 else ''}que {juntar(string)}")
                if not retornar:
                    print(retorno)
                retornos.append(retorno)
            if busca == "ultima":
                break
    if retornar:
        return retornos
