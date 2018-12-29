diag.gama <- function(modelo=fit.model,iden=c(0,0,0,0,0,0,0,0),nome=seq(along = model.matrix(modelo)[,1]),res="D",del=F,mv=F,maxit=20) {

#
# Descri��o e detalhes:
# A sa�da ter� oito gr�ficos:
# 1�) Influ�ncia na Loca��o. O gr�fico feito � das dist�ncias de Cook contra os valores ajustados. Utilizou-se o crit�rio
#     de destacar observa��es maiores do que duas vezes a m�dia de todas as dist�ncias obtidas;
# 2�) Influ�ncia Loca��o/Escala. A medida C, que � um aperfei�oamento do DFFIT e tamb�m � conhecida como dist�ncia de Cook
#     modificada, foi utilizada para medir a influ�ncia das observa��es nos par�metros de loca��o e escala. O crit�rio
#     foi o de destacar observa��es maiores do que duas vezes a m�dia de todas as dist�ncias obtidas;
# 3�) Influ�ncia Local. A influ�ncia local consiste em procurar pontos que sob pequenas perturba��es causam varia��es
#     muito grandes nos resultados. O dmax � o autovetor que corresponde ao maior autovalor da matriz do processo de
#     perturba��es. Para maiores detalhes veja Paula (2003, p�gs.50-54 e 65-66). O crit�rio foi o de destacar observa��es
#     maiores do que duas vezes a m�dia de todos os dmax's. Na influ�ncia local utiliza-se a matriz de informa��o de Fisher
#     observada. Como estamos utilizando a matriz esperada, os resultados obtidos s�o apenas aproximados se a liga��o
#     utilizada n�o for a can�nica;
# 4�) Fun��o de Liga��o. O gr�fico feito � do preditor linear ajustado (eta) contra a vari�vel dependente ajustada (z).
#     Segundo McCullagh e Nelder (1989, p�g.401), o padr�o esperado � de uma linha reta. Para fun��es de liga��o da
#     fam�lia pot�ncia uma curvatura dos pontos acima da reta sugere uma liga��o de uma pot�ncia maior que a utilizada,
#     enquanto que uma curvatura abaixo da reta uma pot�ncia menor. Conforme sugerido, � adicionado uma reta suavizada
#     pelo m�todo lowess robusto e tamb�m uma linha tracejada com inclina��o de 45�. O m�todo deve ser utilizado com
#     cautela, uma vez que por ex.para a binomial ele n�o � informativo;
# 5�) Pontos Alavanca 1. Para os MLG's a matriz H=sqrt(W)%*%X%*%solve(t(X)%*%W%*%X)%*%t(X)%*%sqrt(W) � interpretada como
#     sendo a matriz de proje��o da solu��o de m�nimos quadrados da regress�o linear de z contra X com pesos W. Assim,
#     sugere-se utilizar h=diag(H) para detectar a presen�a de pontos alavanca no modelo de regress�o normal ponderado. Um
#     ponto � considerado alavanca (leverage) quando este exerce uma forte influ�ncia no seu valor ajustado. O crit�rio foi
#     o de destacar observa��es maiores do que duas vezes a m�dia de todos os h�s, que nesse caso resume-se a duas vezes
#     o n�mero de par�metros do modelo, dividido pelo n�mero de observa��es.
#     A medida de alavanca h depende da liga��o atrav�s dos pesos. Como o gr�fico de alavanca � feito dos h's contra as
#     m�dias, temos uma id�ia do que esperar dependendo da liga��o escolhida.
#	Na liga��o log, o peso � constante (igual a 1).
#	Na liga��o can�nica (inversa, 1/mu) o peso � a m�dia ao quadrado (mu^2).
#	Na liga��o identidade (mu) o peso � o inverso da m�dia ao quadrado (1/mu^2).
# 6�) Pontos Alavanca 2. Comentamos no quinto gr�fico que a medida h tem uma forte depend�ncia dos pesos conforme a
#     liga��o escolhida. Assim, sugerimos uma medida h modificada que se d� por hm=diag(HM), em que
#     HM=X%*%solve(t(X)%*%W%*%X)%*%t(X). A id�ia por tr�s dela � de tentar eliminar a forte depend�ncia com os pesos e
#     facilitar a detec��o dos pontos alavanca. Obviamente a medida n�o elimina toda a depend�ncia, uma vez que HM ainda
#     depende de W, mas podemos utiliz�-la adicionalmente � medida h j� tradicionalmente sugerida. Vale notar que se for
#     escolhida uma liga��o em que W seja uma matriz identidade, ent�o h=hm. Hosmer e Lemeshow (2000, p�gs.169 a 173)
#     discutem as duas medidas para a regress�o log�stica. Parece n�o existir estudos muito aprofundados de hm, mas
#     Hosmer e Lemeshow discutem cr�ticas feitas por Pregibon � medida h com rela��o a depend�ncia de W e cr�ticas feitas
#     por Lesaffre em tentar ignorar a informa��o contida em W. Por fim, sugerem que ambas sejam utilizadas com cautela;
# 7�) Pontos Aberrantes. Um ponto � aberrante (discrepante, outlier) se o seu valor estiver mal ajustado pelo modelo.
#     Adicionamos linhas tracejadas em -2 e 2. Assim, se os res�duos escolhidos forem aproximadamente normais,
#     esperamos que cerca de 5% dos pontos possam estar um pouco fora desses limites. Mesmo sem normalidade, o gr�fico
#     serve para inspecionar valores mal ajustados. Deve-se no entando tomar cuidado pois sabemos que por ex.o res�duo
#     de Pearson � assim�trico. Esse gr�fico serve como indica��o para detectar valores aberrantes marginalmente.
#     Devido o desconhecimento da distribui��o dos res�duos e se o objetivo for detectar valores conjuntamente aberrantes
#     deve-se construir o gr�fico de envelopes;
# 8�) Fun��o de Vari�ncia. McCullagh e Nelder (1989, p�g.400) sugere o gr�fico dos res�duos absolutos contra os valores
#     ajustados (ou contra os valores ajustados transformados em escala constante) para checar se a fun��o de vari�ncia
#     adotada � adequada. O padr�o esperado � de n�o encontrarmos nenhuma tend�ncia. Fun��es de vari�ncia erradas ir�o
#     resultar em tend�ncias dos res�duos com a m�dia. Tend�ncias positivas indicam que a fun��o de vari�ncia est�
#     crescendo muito devagar com a m�dia, ent�o deve-se aumentar a pot�ncia (no caso de uma fun��o de vari�ncia da
#     fam�lia pot�ncia). Uma linha suavizada pelo m�todo lowess robusto � adicionada para ajudar na procura de tend�ncias.
#
# Os dados devem estar dispon�veis pelo comando attach( ).
#
# Argumentos obrigat�rios:
# modelo: deve-se informar o objeto onde est� o ajuste do modelo com distribui��o gama, caso n�o seja informado, a
# 	  fun��o procurar� o ajuste no objeto fit.model;
#
# Argumentos opcionais:
# iden: caso deseje, informe o n�mero de observa��es que ir� querer destacar em cada gr�fico. O vetor deve conter 8
#	posi��es de n�meros inteiros. A ordem que deve ser informada � a mesma em que os gr�ficos s�o feitos. Os
#	componentes do vetor iguais a 0 indicam que n�o se quer que identifique pontos, se for um inteiro positivo ir�
#	automaticamente nos gr�ficos respectivos permitir que identifiquemos o n�mero de pontos solicitados e qualquer
#	outro valor (negativo ou decimal) parar nos gr�ficos e solicitar que especifiquemos o n�mero de pontos a ser
#	destacado. O padr�o � c(0,0,0,0,0,0,0,0) caso n�o se entre com nada e c(-1,-1,-1,-1,-1,-1,-1,-1) caso se entre
#	com qualquer coisa que n�o seja um vetor de 8 posi��es, como por ex.-1;
# nome: esse argumento s� � utilizado caso algum dos componentes do vetor da op��o iden n�o seja 0. Caso n�o seja
#	informado nada, os pontos identificados ser�o os n�meros da ordem em que est�o no banco de dados (�ndices).
#	Caso se queira, pode-se informar um vetor de nomes ou de identifica��es alternativas. Obrigatoriamente
#	esse vetor deve ter o mesmo comprimento do banco de dados;
# res: permite-se a escolha dos res�duos que ser�o utilizados nos gr�ficos de pontos aberrantes, da fun��o
#      de liga��o e na medida de influ�ncia na loca��o e na escala. As op��es dos res�duos s�o: "Q" quantil (ver Dunn e
#      Smyth, 1996), "D" componente do desvio, "P" Pearson padronizado, "A" Anscombe e "W" Williams. A op��o padr�o � a "D";
# del: se for T (True) far� com que a fun��o calcule o res�duo da i-�sima observa��o do ajuste que foi feito com
#      ela 'deletada' do banco de dados. Portanto, essa op��o ir� fazer com que o tempo de processamento da fun��o
#      cres�a proporcionalmente ao n�mero de observa��es no banco de dados. O valor F (False) far� com que
#      se calcule os res�duos do pr�prio ajuste (deleted residuals). O padr�o � F;
# mv: o valor T (True) far� com se obtenha a estimativa de m�xima verossimilhan�a (EMV) para o par�metro de
#     dispers�o. O valor F (False) indicar� a escolha pela estimativa consistente pelo m�todo dos momentos. O
#     padr�o � F. Note que como a EMV � razoavelmente mais demorada para ser obtida, a fun��o demorar� mais
#     para rodar. Para obter a EMV a biblioteca MASS deve estar presente, no entanto n�o requer-se que seja
#     carregada previamente;
# maxit: essa op��o s� � utilizada se del=T. Ela � utilizada nos ajustes feitos sem as observa��es e indica o m�ximo
#	 de itera��es permitidas nos ajustes. McCullagh e Nelder (1989) sugerem que aproxima��es de 1 itera��o
#	 podem ser utilizadas. O padr�o � maxit=20.
#
# A fun��o retorna os seguintes valores: ResQuantil, ResCompDesv, ResAnscombe, ResPearsonStd, ResWilliams, Di, Ci, Dmax e h.
#
# Autor: Frederico Zanqueta Poleto <fred@poleto.com>, arquivo dispon�vel em http://www.poleto.com
#
# Refer�ncias:
# DUNN, K. P., and SMYTH, G. K. (1996). Randomized quantile residuals. J. Comput. Graph. Statist. 5, 1-10
#    [http://www.statsci.org/smyth/pubs/residual.html e http://www.statsci.org/smyth/pubs/residual.ps]
# HOSMER, D. W. e LEMESHOW, S. (2000). Applied Logistic Regression. John Wiley & Sons, New York.
# MCCULLAGH, P. e NELDER, J. A. (1989). Generalized Linear Models. 2� ed. Chapman and Hall, London.
# PAULA, G. A. (2003). Modelos de Regress�o com apoio computacional. IME-USP, S�o Paulo. [N�o publicado,
#    dispon�vel em http://www.ime.usp.br/~giapaula/Book.pdf]
#
# Exemplos:
# diag.gama(ajuste,iden=c(1,5,2,0,4,3,0,0),nome=estados)
# diag.gama(ajuste,iden=-1)
#

if(class(modelo)[1] != "glm") {
	stop(paste("\nA classe do objeto deveria ser glm e nao ",class(modelo),"!!!\n"))
}
if(modelo$family[[1]] != "Gamma") {
	stop(paste("\nA familia do objeto deveria ser Gamma e nao ",modelo$family[[1]],"!!!\n"))
}

if(length(iden)<8) {
	iden<-c(-1,-1,-1,-1,-1,-1,-1,-1)
}

X <- model.matrix(modelo)
n <- nrow(X)
p <- ncol(X)
w <- modelo$weights
W <- diag(w)
Fis <- t(X)%*%W%*%X
V <- solve(Fis)
H <- sqrt(W)%*%X%*%V%*%t(X)%*%sqrt(W)
h <- diag(H)

#para evitar divis�o por 0 ao studentizar os residuos, mas tentando manter o valor exagerado da alavanca
h[round(h,15)==1]<-0.999999999999999

y <- modelo$y
m <- predict(modelo,type="response")
mut <- log(m) #McCullagh e Nelder (1989), p�g.398 est� 2*log(m), mas resolvendo a integral para obter uma transforma��o constante pelo Maple obtive log(m)
pl <- predict(modelo)
adj <- pl+residuals(modelo,type="working") #vari�vel dependente ajustada

if(mv==F) {
	fi <- (n-p)/sum((resid(modelo,type="response")/m)^2)
} else {
	library("MASS")
	fi <- 1/gamma.dispersion(modelo)
}
rp <- resid(modelo,type="pearson")*sqrt(fi)

link<-modelo$family["link"]
if(del==F) {
	ts <- rp/sqrt(1-h)
	td <- resid(modelo,type="deviance")*sqrt(fi/(1-h))
	ra <- 3*sqrt(fi)*( y^(1/3) - m^(1/3) )/(m^(1/3))
	rq <- qnorm( pgamma(y,fi,fi/m) )
	di <- (h/((1-h)*p))*(ts^2)
	rw <- sign(y-m)*sqrt((1-h)*(td^2)+(h*ts^2))
} else {
	tdi <- numeric(n)
	rai <- numeric(n)
	rqi <- numeric(n)
	tsi <- numeric(n)
	dii <- numeric(n)
	rwi <- numeric(n)
	if (is.null(version$language) == T) {
		#No S-Plus, a op��o start � para entrar com o preditor linear
		pm<-predict(modelo)
	} else {
		#No R, a op��o start � para entrar com os coeficientes
		pm<-coef(modelo)
	}
	for(i in 1:n) {
		if ( (is.null(version$language) == T && link == "Log: log(mu)") | (is.null(version$language) == F && link == "log") ) {
			fiti <- glm(y ~ X -1,family=Gamma(link=log),subset=-i,maxit=maxit,start=pm)
		} else {
			if ( (is.null(version$language) == T && link == "Inverse: 1/mu") | (is.null(version$language) == F && link == "inverse") ) {
				fiti <- glm(y ~ X -1,family=Gamma,subset=-i,maxit=maxit,start=pm)
			} else {
				if ( (is.null(version$language) == T && link == "Identity: mu") | (is.null(version$language) == F && link == "identity") ) {
					fiti <- glm(y ~ X -1,family=Gamma(link=identity),subset=-i,maxit=maxit,start=pm)
				} else {
					stop(paste("\nEsta funcao so aceita as ligacoes: canonica, log e identidade!!!\nLigacao ",link," desconhecida!!!\n"))
				}
			}
		}
		Xi <- X[-i,]
		wi <- fiti$weights
		Wi <- diag(wi)
		Fi <- t(Xi)%*%Wi%*%Xi
		Vi <- solve(Fi)
		if(mv==F) {
			fii <- ((n-1)-p)/sum((resid(fiti,type="response")/(fitted(fiti)))^2)
		} else {
			fii <- 1/gamma.dispersion(fiti) #Fun��o gamma.shape retorna phi do texto, gamma.shape$alpha=1/gamma.dispersion
		}
		yi <- y[i]
		mi <- predict(fiti,as.data.frame(X),type="response")[i]
		if ( (is.null(version$language) == T && link == "Log: log(mu)") | (is.null(version$language) == F && link == "log") ) {
			hi <- t(as.matrix(X[i,]))%*%Vi%*%as.matrix(X[i,])
		} else {
			if ( (is.null(version$language) == T && link == "Inverse: 1/mu") | (is.null(version$language) == F && link == "inverse") ) {
				hi <- (mi^2)*t(as.matrix(X[i,]))%*%Vi%*%as.matrix(X[i,])
			} else {
				if ( (is.null(version$language) == T && link == "Identity: mu") | (is.null(version$language) == F && link == "identity") ) {
					hi <- (mi^(-2))*t(as.matrix(X[i,]))%*%Vi%*%as.matrix(X[i,])
				} else {
					stop(paste("\nEsta funcao so aceita as ligacoes: canonica, log e identidade!!!\nLigacao ",link," desconhecida!!!\n"))
				}
			}
		}
		tdi[i] <- sign(yi-mi)*sqrt(2*((yi/mi)-log(yi/mi)-1)*(fii/(1+hi)))
		rai[i] <- 3*sqrt(fii)*( yi^(1/3) - mi^(1/3) )/(mi^(1/3))
		rqi[i] <- qnorm( pgamma(yi,fii,fii/mi) )
		tsi[i] <- ((yi-mi)*sqrt(fii/(1+hi)))/mi
		dii[i] <- (fi/p)*t(fiti$coef-modelo$coef)%*%Fis%*%(fiti$coef-modelo$coef)
		rwi[i] <- sign(yi-mi)*sqrt((1-hi)*(tdi[i]^2)+(hi*tsi[i]^2))
	}
	td<-tdi
	ra<-rai
	rq<-rqi
	ts<-tsi
	di<-dii
	rw<-rwi
}
A <- diag(rp)%*%H%*%diag(rp)
dmax <- abs(eigen(A)$vec[,1]/sqrt(eigen(A)$val[1]))

if(res=="Q") {
	tipor<-"Res�duo Quantil"
	r<-rq
} else {
	if(res=="D") {
		tipor<-"Res�duo Componente do Desvio"
		r<-td
	} else {
		if(res=="P") {
			tipor<-"Res�duo de Pearson Padronizado"
			r<-ts
		} else {
			if(res=="A") {
				tipor<-"Res�duo de Anscombe"
				r<-ra
			} else {
				if(res=="W") {
					tipor<-"Res�duo de Williams"
					r<-rw
				} else {
					stop(paste("\nVoce nao escolheu corretamente um dos residuos disponiveis!!!\n"))
				}
			}
		}
	}
}
ci <- sqrt( ((n-p)*h) / (p*(1-h)) )*abs(r)

if ( (is.null(version$language) == T && link == "Log: log(mu)") | (is.null(version$language) == F && link == "log") ) {
	hm <- h
} else {
	if ( (is.null(version$language) == T && link == "Inverse: 1/mu") | (is.null(version$language) == F && link == "inverse") ) {
		hm <- h/(m^2)
	} else {
		if ( (is.null(version$language) == T && link == "Identity: mu") | (is.null(version$language) == F && link == "identity") ) {
			hm <- h/(m^(-2))
		} else {
			stop(paste("\nEsta funcao so aceita as ligacoes: canonica, log e identidade!!!\nLigacao ",link," desconhecida!!!\n"))
		}
	}
}

par(mfrow=c(2,4))

plot(m,di,xlab="Valor Ajustado", ylab="Dist�ncia de Cook",main="Influ�ncia na Loca��o", ylim=c(0,max(di,2*mean(di))), pch=16)
abline(2*mean(di),0,lty=2)
while ( (!is.numeric(iden[1])) || (round(iden[1],0) != iden[1]) || (iden[1] < 0) ) {
	cat("Digite o num.de pontos a ser identificado (0=nenhum) e <enter> para continuar\n")
	out <- readline()
	iden[1]<-as.numeric(out)
}
if(iden[1]>0) {identify(m,di,n=iden[1],labels=nome)}

plot(m,ci,xlab="Valor Ajustado", ylab="Dist�ncia de Cook Modificada",main="Influ�ncia Loca��o/Escala", ylim=c(0,max(ci,2*mean(ci))), pch=16)
abline(2*mean(ci),0,lty=2)
while ( (!is.numeric(iden[2])) || (round(iden[2],0) != iden[2]) || (iden[2] < 0) ) {
	cat("Digite o num.de pontos a ser identificado (0=nenhum) e <enter> para continuar\n")
	out <- readline()
	iden[2]<-as.numeric(out)
}
if(iden[2]>0) {identify(m,ci,n=iden[2],labels=nome)}

plot(m,dmax,xlab="Valor Ajustado", ylab="dmax",main="Influ�ncia Local", ylim=c(0,max(dmax,2*mean(dmax))), pch=16)
abline(2*mean(dmax),0,lty=2)
while ( (!is.numeric(iden[3])) || (round(iden[3],0) != iden[3]) || (iden[3] < 0) ) {
	cat("Digite o num.de pontos a ser identificado (0=nenhum) e <enter> para continuar\n")
	out <- readline()
	iden[3]<-as.numeric(out)
}
if(iden[3]>0) {identify(m,dmax,n=iden[3],labels=nome)}

plot(adj,pl,xlab="Vari�vel Dependente Ajustada",ylab="Preditor Linear Ajustado",main="Fun��o de Liga��o", pch=16)
lines(lowess(adj,pl))
abline(a=0,b=1,lty=2)
while ( (!is.numeric(iden[4])) || (round(iden[4],0) != iden[4]) || (iden[4] < 0) ) {
	cat("Digite o num.de pontos a ser identificado (0=nenhum) e <enter> para continuar\n")
	out <- readline()
	iden[4]<-as.numeric(out)
}
if(iden[4]>0) {identify(adj,pl,n=iden[4],labels=nome)}

plot(m,h,xlab="Valor Ajustado",ylab="Medida h",main="Pontos Alavanca 1",ylim=c(0,max(h,2*p/n)),pch=16)
abline(2*p/n,0,lty=2)
while ( (!is.numeric(iden[5])) || (round(iden[5],0) != iden[5]) || (iden[5] < 0) ) {
	cat("Digite o num.de pontos a ser identificado (0=nenhum) e <enter> para continuar\n")
	out <- readline()
	iden[5]<-as.numeric(out)
}
if(iden[5]>0) {identify(m,h,n=iden[5],labels=nome)}

plot(m,hm,xlab="Valor Ajustado",ylab="Medida h Modificada",main="Pontos Alavanca 2",ylim=c(0,max(hm,2*mean(hm))),pch=16)
abline(2*mean(hm),0,lty=2)
while ( (!is.numeric(iden[6])) || (round(iden[6],0) != iden[6]) || (iden[6] < 0) ) {
	cat("Digite o num.de pontos a ser identificado (0=nenhum) e <enter> para continuar\n")
	out <- readline()
	iden[6]<-as.numeric(out)
}
if(iden[6]>0) {identify(m,hm,n=iden[6],labels=nome)}

plot(m,r,xlab="Valor Ajustado",ylab=tipor,main="Pontos Aberrantes", ylim=c(min(r)-1,max(r)+1), pch=16)
abline(2,0,lty=2)
abline(-2,0,lty=2)
while ( (!is.numeric(iden[7])) || (round(iden[7],0) != iden[7]) || (iden[7] < 0) ) {
	cat("Digite o num.de pontos a ser identificado (0=nenhum) e <enter> para continuar\n")
	out <- readline()
	iden[7]<-as.numeric(out)
}
if(iden[7]>0) {identify(m,r,n=iden[7],labels=nome)}

plot(m,abs(r),xlab="Valor Ajustado",ylab=paste(tipor," Absoluto",sep=""),main="Fun��o de Vari�ncia", pch=16)
lines(lowess(m,abs(r)))
while ( (!is.numeric(iden[8])) || (round(iden[8],0) != iden[8]) || (iden[8] < 0) ) {
	cat("Digite o num.de pontos a ser identificado (0=nenhum) e <enter> para continuar\n")
	out <- readline()
	iden[8]<-as.numeric(out)
}
if(iden[8]>0) {identify(m,abs(r),n=iden[8],labels=nome)}

par(mfrow=c(1,1))

list(ResQuantil=rq,ResCompDesv=td,ResAnscombe=ra,ResPearsonStd=ts,ResWilliams=rw,Di=di,Ci=ci,Dmax=dmax,h=h)
}
