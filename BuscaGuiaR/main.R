formatar <- function(texto,ct=34,cf=49, est=c(1,3)) {
  cat(paste0("\033[", paste(paste(ct, collapse=";"),
                            paste(cf, collapse=";"),
                            paste(est, collapse=";"), sep=";"),
             "m", texto, "\033[0m"))}

adicionar <- function(exceto=NULL){
  exceto <- tolower(exceto)
  arquivo <- readLines("../ultimo.properties", encoding = "UTF-8")
  mtx <- matrix(unlist(strsplit(arquivo, "=")), ncol=2, byrow = TRUE)
  for (i in 1:nrow(mtx)){
    if (!(mtx[i, 1] %in% exceto)){
      mtx[i,2] <- as.numeric(mtx[,2])+1
    }
  }
  writeLines(paste(mtx[,1],mtx[,2],sep="="),"../ultimo.properties")
}

baixar_guia <- function(nome, numeros, exceto=NULL){
  exceto <- tolower(exceto)
  for (x in numeros) {
    if (!(is.null(exceto))){
      if (paste(nome,x,sep="_") %in% unlist(exceto) | nome %in% unlist(exceto)){
        next
      }
    }
    print(paste(nome,x,sep="_"))
    url <- sprintf('https://supac.ufba.br/sites/supac.ufba.br/files/%s_%s.html',
                   nome, x)
    dir.create(file.path("arquivos_csv",toupper(nome)),
               showWarnings = F,recursive = T)
    temp_file <- tempfile(fileext = ".html")
    download.file(url, temp_file, quiet = TRUE)
    pagina <- paste(readLines(temp_file, encoding="latin1", warn = FALSE),
                    collapse="")
    
    if (grepl("UNIVERSIDADE FEDERAL DA BAHIA - MATRÃ\u008dCULA",
              pagina, fixed=TRUE)){
      pagina <- paste(readLines(temp_file, encoding="utf8", warn = FALSE),
                      collapse="")
    }
    
    tipo <- startsWith(pagina,"<!-")
    sem <- tail(strsplit(strsplit(pagina,'<br>')[[1]][1], " ")[[1]],1)

    tabela <- strsplit(substr(pagina,
                              regexpr('<table border', pagina)[[1]],
                              regexpr('</table>', pagina)[[1]]-1),"<tr>")
    
    df <- data.frame(matrix(ncol=7))
    colnames(df) <- c("Disciplina","Turma","Coleg.","Vagas Ofe",
                      "Dia","Horário","Docente")
    for (y in 5:length(tabela[[1]])){
      l <- strsplit(tabela[[1]][y],ifelse(tipo,"<td><font size=\"2\">",
                                          "<td><FONT SIZE=2>"))[[1]][2:8]
      l <- ifelse(rep(tipo,7), unlist(strsplit(l,"</font>"))[c(TRUE,FALSE)],l)
      adicionar <- as.vector(sapply(l, function(z) ifelse(trimws(z) == "",
                                                          NA, z)))
      df <- rbind(df,adicionar)
    }
    nome_arquivo <- sprintf('arquivos_csv/%s/%s_%03d_(%s).csv', toupper(nome),
                            nome, as.integer(x), sem)
    write.csv(df, nome_arquivo, row.names = FALSE)
  }
}

baixar <- function(todos = FALSE, exceto = NULL){
  arquivo <- readLines("../ultimo.properties", encoding = "UTF-8")
  mtx <- matrix(unlist(strsplit(arquivo, "=")), ncol=2, byrow = TRUE)
  bsc <- setNames(as.numeric(mtx[,2]), mtx[,1])
  for (nome in names(bsc)) {
    valor <- bsc[nome]
    if (todos){
      num <- 1:valor
    } else {
      num <- valor
    }
    baixar_guia(nome, num, exceto)
  }
}

pesquisa <- function(item, unidade=NULL, busca="ultima", tipo="código",
                     aviso=c(0,0), formatado=TRUE, fore=34, back=49,
                     estilo=c(1,3), multi=FALSE, retornar=FALSE, tabela=FALSE,
                     ocultar=rep(FALSE,10)) {
  
  busca <- tolower(busca)
  item <- toupper(item)
  tipo <- tolower(tipo)
  
  dias <- c(SEG="Segunda", TER="Terça", QUA="Quarta", QUI="Quinta",
            SEX="Sexta", SAB="Sábado", DOM="Domingo",
            CMB="A Combinar")
  
  if (is.null(unidade)) {
    if (tipo == "código"){
      unidade <- substr(item, 1, 3)
    } else {
      unidade <- list.files("arquivos_csv")
    }
  } else {
    unidade <- toupper(unidade)
  }
  
  cursosprop <- readLines("../cursos.properties", encoding='utf-8')
  mtx_c <- matrix(unlist(strsplit(cursosprop, "=")), ncol=2, byrow=TRUE)
  nomes <- setNames(mtx_c[,2],mtx_c[,1])
  
  unidadesprop <- readLines("../unidades.properties", encoding='utf-8')
  mtx_u <- matrix(unlist(strsplit(unidadesprop, "=")), ncol=2, byrow=TRUE)
  unidades <- setNames(mtx_u[,2],mtx_u[,1])
  

  frm <- function(obj, fb=fore, bb=back, est=estilo) {
    if (formatado) {
      return(paste0("\033[", paste(paste(fb, collapse=";"),
                                   paste(bb, collapse=";"),
                                   paste(est, collapse=";"), sep=";"),
                    "m", obj, "\033[0m"))
      } else {return(obj)}
  }
  
  defcor <- function(vt) ifelse(multi, c(31:37, 90:96)[unlist(vt[multi])], fore)
  
  filtro <- function(dataf, coluna, valor, i=0) {
    colu <- dataf[[coluna]]
    if (i==0){
      ind_1 <- which(colu == valor)[1]
      vec <- which(!is.na(colu) & 1:nrow(dataf) > ind_1)[1]
      ind_2 <- ifelse(is.na(vec),nrow(df),vec)
      dataf_2 <- dataf[ind_1:(ind_2 - 1),]
      rownames(dataf_2) <- NULL
    } else {
      colu <- toupper(colu)
      ind_0 <- which(colu == valor & (c(TRUE, colu[-length(colu)] != valor)))[i]
      ind_1 <- which(colu == valor & (c(colu[-1] != valor, TRUE)))[i]
      ind_2 <- tail(which(!is.na(dataf[2]) & 1:nrow(dataf) <= ind_0), 1)
      ind_3 <- head(which(!is.na(dataf[2]) & 1:nrow(dataf) > ind_1), 1)
      print(paste(ind_0,ind_1,ind_2,ind_3))
      if (length(ind_3) == 0) ind_3 <- ind_2+1
      dataf_2 <- dataf[ind_2:(ind_3-1),]
      rownames(dataf_2) <- NULL
      dataf_2[1,8:9] <- dataf[tail(which(!is.na(dataf[8]) &
                                           1:nrow(dataf) <= ind_2),1),8:9]
      print(dataf_2)
    }
    return(dataf_2)
    
  }
  
  preencher <- function(cln) {
    if (length(cln) > 1){
      for (i in 2:length(cln)) {
        if (is.na(cln[i])) {cln[i] <- cln[i-1]}
      }
    }
    return(cln)
  }
  
  juntar <- function(lista) {
    if (length(lista) > 1) {
      return(paste(paste(lista[1:(length(lista) - 1)], collapse = ", "), "e",
                   lista[length(lista)]))
    } else {
      return(lista[1])
    }
  }
  
  if (any(!(unidade %in% list.files("arquivos_csv")))){
    stop('Parâmetro "unidade" inválido.')}
  if (!(busca %in% c("semestre", "todas", "ultima")) && 
      !(grepl("^\\d{4}-\\d$", busca))){
    stop('Parâmetro "busca" inválido.')}
  if (!(tipo %in% c("código", "matéria", "docente"))){
    stop('Parâmetro "tipo" inválido.')}
  
  retornos <- c()
  
  for (uni in unidade){
    procura <- list.files(paste0("arquivos_csv/", uni))
    if (busca != "semestre"){
      procura <- tail(procura,1)
    } else if (grepl("^\\d{4}-\\d$", busca)){
      procura <- rev(procura[grepl(busca, procura)])
    } else {
      procura <- rev(list.files(paste0("arquivos_csv/", uni)))
    }
    for (proc in procura){
      df <- read.csv(paste0("arquivos_csv/", uni, "/", proc))
      
      if (length(which(apply(df, 1, function(v) all(!is.na(v))))) == 0) next
      mtx_1 <- strsplit(df$Disciplina, " - ")
      df$Código <- unlist(lapply(mtx_1, function(x) x[1]))
      df$Matéria <- unlist(lapply(mtx_1, function(x) x[2]))
      if (tipo == "código"){
        retorno <- if (!(item %in% df$Código))
          paste("A matéria de código", item, "não foi encontrada",
                "no guia de matrícula Nº", as.numeric(substr(proc, 5, 7)),
                "da unidade", uni) else NULL
        } else if (tipo == "matéria"){
        retorno <- if (!(item %in% df$Matéria))
          paste("A matéria", item, "não foi encontrada",
                "no guia de matrícula Nº",
                as.numeric(substr(proc, 5, 7)), "da unidade", uni) else NULL
        } else {
        retorno <- if (!(item %in% unname(sapply(df$Docente,toupper))))
          paste("O docente", item, "não foi encontrado",
                "no guia de matrícula Nº", as.numeric(substr(proc, 5, 7)),
                "da unidade", uni) else NULL
        }
      
      if (!is.null(retorno)){
        if (aviso[1]) message(retorno)
        if (aviso[2]) retornos <- c(retornos, retorno)
        next
      }
      
      df <- df[!apply(df, 1, function(a) all(is.na(a))), ]
      rownames(df) <- NULL
      bsc <- paste0(toupper(substring(tipo, 1, 1)), substring(tipo, 2))
      
      it <- if (bsc != "Docente") 0 else 1:length(which(
        toupper(df$Docente) == item &
          (c(toupper(df$Docente[-1]) != item, TRUE))))
      for (ite in it){
        ndf_1 <- filtro(df,bsc,item,ite)
        
        it_tms <- sprintf("%06d", na.omit(ndf_1$Turma))
        
        ndf_1$Turma <- ifelse(is.na(ndf_1$Turma),
                              NA, sprintf("%06d", ndf_1$Turma))
        
        tms <- list()
        for (tm in it_tms){
          tms <- c(tms, frm(tm, fb=defcor(c(length(tms)%%4+1,2)),
                            bb=back, est=estilo))
        }
        
        resp <- list(
          codigo = ndf_1$Código[1],
          materia = ndf_1$Matéria[1],
          semestre = substr(proc, 10, 15),
          guia = as.numeric(substr(proc, 5, 7)),
          turmas = tms,
          unidade = paste0("(",uni,") ", unidades[tolower(uni)]),
          plural_1 = ifelse(length(it_tms)==1,"a turma","as turmas")
        )
        if (tabela){
          dfr <- ndf_1
          dfr[is.na(dfr)] <- ""
          colunas <- c(!(ocultar[1] && ocultar[2]), !ocultar[6], !ocultar[7],
                       !ocultar[8], !ocultar[9], !ocultar[9], !ocultar[10],
                       FALSE, FALSE) 
          dfr <- dfr[,colunas]
          if (!(retornar)){
            cat(paste0(if (!(ocultar[4])) paste0("No guia de matrícula Nº ",
                                               resp["guia"]) else "",
                       if (!(ocultar[3])) paste0(" (", resp["semestre"],
                                               ")") else "",
                       if (!(ocultar[5])) paste0(" da unidade: ",
                                               resp["unidade"]) else "", "\n"))
            print(dfr)
          }
          retornos <- c(retornos, dfr)
          break
        }
        for (turm in 1:length(resp$turmas)){
          resp[[paste0("turma_",turm)]] <- it_tms[turm]
          ndf_2 <- filtro(ndf_1, "Turma", resp[[paste0("turma_", turm)]])
          ndf_2 <- ndf_2[!apply(ndf_2, 1, function(z) all(is.na(z))), ]
          rownames(ndf_2) <- NULL
          cursos <- unique(na.omit(ndf_2$Coleg.))
          vagas <- ndf_2[match(cursos,ndf_2$Coleg.),3:4]
          resp[[paste0("plural_",turm,"_2")]] <- ifelse(length(cursos)==1,
                                                        "o curso", "os cursos")
          
          tyc <- list()
          
          for (it_tyc in paste(cursos,"-", nomes[as.character(cursos)])){
            tyc <- c(tyc, frm(it_tyc, fb=defcor(c((turm-1)%%4+1,4)),
                              bb=back, est=estilo))
          }
          resp[[paste0("turma_",turm,"_cursos")]] <- tyc
          
          if (nrow(vagas)==1){
            vgs <- paste(if(ocultar[8]) '*' else
              frm(vagas[1,2], fb=defcor(c((turm-1)%%4+1,13)),
                  bb=back, est=estilo),
                         ifelse(vagas[1,2]==1,"vaga","vagas"))
          } else {
            vgs <- juntar(paste(if(ocultar[8]) rep('*',
                                                   length(vagas[,2])) else
                                   frm(vagas[,2],
                                   fb=defcor(c((turm-1)%%4+1,13)),
                                   bb=back, est=estilo),
                                ifelse(vagas[,2]==1, "vaga para", "vagas para"),
                                if(ocultar[6]) rep('*',length(vagas[,1])) else
                                  frm(paste(vagas[,1], "-",
                                            nomes[as.character(vagas[,1])]),
                                      fb=defcor(c((turm-1)%%4+1,2)),
                                      bb=back, est=estilo)))
          }
          
          resp[[paste0("vagas_", turm)]] <- vgs
          
          doc <- list()
          for (it_doc in unique(na.omit(ndf_2$Docente))){
            doc <- c(doc, frm(it_doc, fb=defcor(c((turm-1)%%4+1,10)),
                              bb=back, est=estilo))
          }
          resp[[paste0("docentes_", turm)]] <- doc
          horas <- ndf_2[!is.na(ndf_2$Dia) | !is.na(ndf_2$Horário),
                         c("Dia", "Horário")]
          horas$Dia <- preencher(horas$Dia)
          splt <- split(horas$Horário, horas$Dia)
          splt <- splt[order(match(names(splt), names(dias)))]
          
          hrs <- list()
          for (it_splt in names(splt)){
            jnt <- list()
            for (it_jnt in splt[[it_splt]]){
              jnt <- c(jnt, frm(it_jnt, fb=defcor(c((turm-1)%%4+1,12)),
                                bb=back, est=estilo))
            }
            hrs <- c(hrs, paste(frm(dias[[it_splt]],
                                    fb=defcor(c((turm-1)%%4+1,12)),
                                    bb=back, est=estilo),
                                "de", juntar(jnt)))
          }
          resp[[paste0("horarios_", turm)]] <- hrs
          resp[[paste0("plural_", turm, "_3")]] <- ifelse(length(splt)==1,
                                                          "o horário",
                                                          "os horários")
          resp[[paste0("plural_", turm, "_4")]] <- ifelse(
            length(doc)==1, "docente responsável", "docentes responsáveis")
          
          if (length(doc)>1){
            jstrdoc <- list()
            for (it_hdoc in unique(na.omit(ndf_2$Docente))){
              hdoc <- ndf_2[!is.na(ndf_2$Dia) | !is.na(ndf_2$Horário),
                            c("Dia", "Horário", "Docente")]
              hdoc$Dia <- preencher(hdoc$Dia)
              
              hdoc <- hdoc[which(hdoc$Docente == it_hdoc),]
              hspl <- split(hdoc$Horário, hdoc$Dia)
              hspl <- hspl[order(match(names(hspl), names(dias)))]
              
              hrdoc <- list()
              for (it_hspl in names(hspl)){
                hdjnt <- list()
                for (it_hdjnt in hspl[[it_hspl]]){
                  hdjnt <- c(hdjnt, frm(it_hdjnt,
                                        fb=defcor(c((turm-1)%%4+1,12)),
                                        bb=back, est=estilo))
                }
                hrdoc <- c(hrdoc, if(ocultar[9]) '*' else
                                     paste(frm(dias[[it_hspl]],
                                               fb=defcor(c((turm-1)%%4+1,12)),
                                               bb=back, est=estilo),
                                  "de", juntar(hdjnt)))
              }
              
              strdoc <- paste(if(ocultar[10]) '*' else
                                 frm(it_hdoc, fb=defcor(c((turm-1)%%4+1,10)),
                                     bb=back, est=estilo),
                              "responsável por ministrar a disciplina durante",
                              ifelse(length(hspl)==1,"o horário:",
                                     "os horários:"), hrdoc)
              jstrdoc <- c(jstrdoc,strdoc)
            }
            horadoc <- paste0(", sendo: ", juntar(jstrdoc))
          }
          resp[[paste0("horadocentes_", turm)]] <- if(length(doc)==1) "" else
            horadoc
        }
        
        string <- character()
        nturmas <- length(resp[["turmas"]])
        for (it_t in 1:nturmas){
          string <- c(string, paste0(if (nturmas > 1)
            paste("a turma", if(ocultar[6]) '*' else frm(resp[[paste0("turma_",
                                                                      it_t)]],
                                 fb=defcor(c((it_t-1)%%4+1,3)),
                                 bb=back, est=estilo), ""),
            "foi ofertada para ", resp[[paste0("plural_", it_t, "_2")]],
            ": ", if(ocultar[7]) '*' else juntar(resp[[paste0("turma_", it_t,
                                                              "_cursos")]]),
            ", com ", resp[[paste0("vagas_", it_t)]],
            " com ", resp[[paste0("plural_", it_t, "_3")]],
            ": ", if(ocultar[9]) '*' else juntar(resp[[paste0("horarios_",
                                                              it_t)]]),
            " e: ", if(ocultar[10]) '*' else juntar(resp[[paste0("docentes_",
                                                                 it_t)]]),
            " como ", resp[[paste0("plural_", it_t, "_4")]], " por ministrar ",
            "a disciplina", resp[[paste0("horadocentes_", it_t)]]))
          
        }
        retorno <- paste0("A matéria de código ",
                          if(ocultar[1]) '*' else frm(resp[['codigo']],
                                                      fb=ifelse(multi,91,fore),
                                                      bb=back, est=estilo),
                          " com o nome ", 
                          if(ocultar[2]) '*' else frm(resp[['materia']],
                                                      fb=ifelse(multi,91,fore),
                                                      bb=back, est=estilo),
                          " foi ofertada no semestre ",
                          if(ocultar[3]) '*' else frm(resp[['semestre']],
                                                      fb=ifelse(multi,91,fore),
                                                      bb=back, est=estilo),
                          " conforme guia de matrícula Nº ",
                          if(ocultar[4]) '*' else frm(resp[['guia']],
                                                      fb=ifelse(multi,91,fore),
                                                      bb=back, est=estilo),
                          " da Unidade: ", if(ocultar[5]) '*' else
                                              frm(resp[['unidade']],
                                                  fb=ifelse(multi,91,fore),
                                                  bb=back, est=estilo),
                          ", com ", resp[['plural_1']],
                          " ", if(ocultar[6]) '*' else juntar(resp[['turmas']]),
                          ", ", if (length(resp[["turmas"]])>1) "em ", "que ",
                          juntar(string), "\n")
        if (!(retornar)){
          cat(retorno)
        }
        retornos <- c(retornos, retorno)
      }
      if (busca == "ultima") break
    }
  }
  if (retornar){
    return(retornos)
  }
}
