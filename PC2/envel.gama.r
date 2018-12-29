envel.gama <- function(modelo=fit.model,iden=0,nome=seq(along = model.matrix(modelo)[,1]),sim=100,conf=.90,res="D",mv=F,quad=T,maxit=20) {

#
# Descri��o e detalhes:
# A sa�da ser� o gr�fico de probabilidade normal com envelopes simulados para um ajuste da distribui��o gama.
#
# A op��o res="C" faz o gr�fico de probabilidade meio-normal com envelopes simulados utilizando a dist�ncia de Cook,
# possibilitando a detec��o de pontos simultaneamente aberrantes e/ou influentes.
#
# Aten��o: a fun��o n�o funcionar� corretamente se o ajuste possuir offsets! Neste caso � preciso adapt�-la como foi
# feito na fun��o envel.pois
#
# Os dados devem estar dispon�veis pelo comando attach( ).
#
# Argumentos obrigat�rios:
# modelo: deve-se informar o objeto onde est� o ajuste do modelo, caso n�o seja informado, a fun��o procurar�
# 	  o ajuste no objeto fit.model;
# 
# Argumentos opcionais:
# iden: caso deseje, informe o n�mero de observa��es que ir� querer destacar. O padr�o � n�o destacar ningu�m (iden=0).
#	Qualquer valor que n�o seja um inteiro positivo (por ex., negativo ou decimal) far� com que a fun��o pergunte
#	o n�mero de pontos ap�s a execu��o;
# nome: esse argumento s� � utilizado caso seja destacado algum ponto no gr�fico. Caso n�o seja informado nada, os pontos
#	identificados ser�o os n�meros da ordem em que est�o no banco de dados (os �ndices). Caso se queira, pode-se
#	informar um vetor de nomes ou de identifica��es alternativas. Obrigatoriamente esse vetor deve ter o mesmo
#	comprimento do banco de dados;
# sim: n�mero de simula��es para gerar a banda de confian�a. Atkinson sugere um m�nimo de 20 simula��es.
#      O padr�o � de 100;
# conf: n�vel de confian�a do envelope. O padr�o � de 90%;
# res: permite-se a escolha dos res�duos. As op��es dos res�duos s�o: "Q" quantil (ver Dunn e Smyth, 1996), "D" componente
#      do desvio, "P" Pearson padronizado, "A" Anscombe, "W" Williams e "C" dist�ncia de Cook. A op��o padr�o � a "D";
# mv: o valor T (True) far� com se obtenha a estimativa de m�xima verossimilhan�a (EMV) para o par�metro de
#     dispers�o. O valor F (False) indicar� a escolha pela estimativa consistente pelo m�todo dos momentos. O
#     padr�o � F. Note que como a EMV � razoavelmente mais demorada para ser obtida, a fun��o demorar� mais
#     para rodar. Para obter a EMV a biblioteca MASS deve estar presente, no entanto n�o requer-se que seja
#     carregada previamente;
# quad: o padr�o (quad=T, True) faz um gr�fico quadrado, enquanto quad=F (False) faz um gr�fico utilizando a �rea m�xima
#       dispon�vel;
# maxit: essa op��o � utilizada nos ajustes de cada simula��o e indica o m�ximo de itera��es permitidas nos ajustes.
#	 O padr�o � maxit=20.
#
# Autor: Frederico Zanqueta Poleto <fred@poleto.com>, arquivo dispon�vel em http://www.poleto.com
#
# Refer�ncias:
# DUNN, K. P., and SMYTH, G. K. (1996). Randomized quantile residuals. J. Comput. Graph. Statist. 5, 1-10
#    [http://www.statsci.org/smyth/pubs/residual.html e http://www.statsci.org/smyth/pubs/residual.ps]
# MCCULLAGH, P. e NELDER, J. A. (1989). Generalized Linear Models. 2� ed. Chapman and Hall, London.
# PAULA, G. A. (2003). Modelos de Regress�o com apoio computacional. IME-USP, S�o Paulo. [N�o publicado,
#    dispon�vel em http://www.ime.usp.br/~giapaula/Book.pdf]
#
# Exemplos:
# envel.gama(ajuste,sim=1000,conf=.95,mv=T,maxit=50)
# envel.gama(ajuste,res="C")
#

if(class(modelo)[1] != "glm") {
	stop(paste("\nA classe do objeto deveria ser glm e nao ",class(modelo),"!!!\n"))
}
if(modelo$family[[1]] != "Gamma") {
	stop(paste("\nA familia do objeto deveria ser Gamma e nao ",modelo$family[[1]],"!!!\n"))
}

alfa<-(1-conf)/2
X <- model.matrix(modelo)
n <- nrow(X)
p <- ncol(X)
w <- modelo$weights
W <- diag(w)
H <- solve(t(X)%*%W%*%X)
H <- sqrt(W)%*%X%*%H%*%t(X)%*%sqrt(W)
h <- diag(H)

#para evitar divis�o por 0 ao studentizar os residuos, mas tentando manter o valor exagerado da alavanca
h[round(h,15)==1]<-0.999999999999999

m<-predict(modelo,type="response")
y<-modelo$y
if(mv==F) {
	fi <- (n-p)/sum((resid(modelo,type="response")/m)^2)
} else {
	library("MASS")
	fi <- 1/gamma.dispersion(modelo) #Fun��o gamma.shape retorna phi do texto, gamma.shape$alpha=1/gamma.dispersion
}

if(res=="Q") {
	tipo<-"Res�duo Quantil"
	r<-qnorm( pgamma(y,fi,fi/m) )
} else {
	if(res=="D") {
		tipo<-"Res�duo Componente do Desvio"
		r<-resid(modelo,type="deviance")*sqrt(fi/(1-h))
	} else {
		if(res=="P") {
			tipo<-"Res�duo de Pearson Padronizado"
			r<-resid(modelo,type="pearson")*sqrt(fi/(1-h))
		} else {
			if(res=="A") {
				tipo<-"Res�duo de Anscombe"
				r<-3*sqrt(fi)*( y^(1/3) - m^(1/3) )/(m^(1/3))
			} else {
				if(res=="W") {
					tipo<-"Res�duo de Williams"
					r<-sign(y-m)*sqrt((1-h)*(( resid(modelo,type="deviance")*sqrt(fi/(1-h)) )^2)+(h*( resid(modelo,type="pearson")*sqrt(fi/(1-h)) )^2))
				} else {
					if(res=="C") {
						tipo<-"Dist�ncia de Cook"
						r<-(h/((1-h)*p))*((resid(modelo,type="pearson")/sqrt(1-h))^2)
					} else {
						stop(paste("\nVoce nao escolheu corretamente um dos residuos disponiveis!!!\n"))
					}
				}
			}
		}
	}
}

link<-modelo$family[[2]]

e <- matrix(0,n,sim)
e1 <- numeric(n)
e2 <- numeric(n)

if (is.null(version$language) == T) {
	#No S-Plus, a op��o start � para entrar com o preditor linear
	pm<-predict(modelo)
} else {
	#No R, a op��o start � para entrar com os coeficientes
	pm<-coef(modelo)
}
mu<-m
for(i in 1:sim) {
	resp <- rgamma(n,fi,fi/mu)
	if ( (is.null(version$language) == T && link == "Log: log(mu)") | (is.null(version$language) == F && link == "log") ) {
		fit <- glm(resp ~ X-1,family=Gamma(link=log),maxit=maxit,start=pm)
	} else {
		if ( (is.null(version$language) == T && link == "Inverse: 1/mu") | (is.null(version$language) == F && link == "inverse") ) {
			fit <- glm(resp ~ X-1,family=Gamma,maxit=maxit,start=pm)
		} else {
			if ( (is.null(version$language) == T && link == "Identity: mu") | (is.null(version$language) == F && link == "identity") ) {
				fit <- glm(resp ~ X-1,family=Gamma(link=identity),maxit=maxit,start=pm)
			} else {
				stop(paste("\nEsta funcao so aceita as ligacoes: canonica, log e identidade!!!\nLigacao ",link," desconhecida!!!\n"))
			}
		}
	}
	w <- fit$weights
	W <- diag(w)
	H <- solve(t(X)%*%W%*%X)
	H <- sqrt(W)%*%X%*%H%*%t(X)%*%sqrt(W)
	h <- diag(H)
	h[round(h,15)==1]<-0.999999999999999
	m <- predict(fit,type="response")
	y <- fit$y
	if(mv==F) {
		phi <- (n-p)/sum((resid(fit,type="response")/m)^2)
	} else {
		phi <- 1/gamma.dispersion(fit)
	}
	e[,i] <- 
	sort( if(res=="Q") {
		qnorm( pgamma(y/(m/phi),phi) )
	} else {
		if(res=="D") {
			resid(fit,type="deviance")*sqrt(phi/(1-h))
		} else {
			if(res=="P") {
				resid(fit,type="pearson")*sqrt(phi/(1-h))
			} else {
				if(res=="A") {
					3*sqrt(phi)*( y^(1/3) - m^(1/3) )/(m^(1/3))
				} else {
					if(res=="W") {
						sign(y-m)*sqrt((1-h)*(( resid(fit,type="deviance")*sqrt(phi/(1-h)) )^2)+(h*( resid(fit,type="pearson")*sqrt(phi/(1-h)) )^2))
					} else {
						if(res=="C") {
							(h/((1-h)*p))*((resid(fit,type="pearson")/sqrt(1-h))^2)
						} else {
							stop(paste("\nVoce nao escolheu corretamente um dos residuos disponiveis!!!\n"))
						}
					}
				}
			}
		}
	})
}

for(i in 1:n) {
	eo <- sort(e[i,])
	e1[i] <- quantile(eo,alfa)
	e2[i] <- quantile(eo,1-alfa)
}

med <- apply(e,1,median)

if(quad==T) {
	par(pty="s")
}
if(res=="C") {
	#Segundo McCullagh e Nelder (1989, p�g.407) e Paula (2003, p�g.57) deve-se usar qnorm((n+1:n+.5)/(2*n+1.125))
	#Segundo Neter et alli (1996, p�g.597) deve-se usar qnorm((n+1:n-.125)/(2*n+0.5))
	qq<-qnorm((n+1:n+.5)/(2*n+1.125))
	plot(qq,sort(r),xlab="Quantil Meio-Normal",ylab=tipo, ylim=range(r,e1,e2), pch=16)
} else {
	qq<-qnorm((1:n-.375)/(n+.25))
	plot(qq,sort(r),xlab="Quantil da Normal Padr�o",ylab=tipo, ylim=range(r,e1,e2), pch=16)
}
lines(qq,e1,lty=1)
lines(qq,e2,lty=1)
lines(qq,med,lty=2)
nome<-nome[order(r)]
r<-sort(r)
while ( (!is.numeric(iden)) || (round(iden,0) != iden) || (iden < 0) ) {
	cat("Digite o num.de pontos a ser identificado (0=nenhum) e <enter> para continuar\n")
	out <- readline()
	iden<-as.numeric(out)
}
if(iden>0) {identify(qq,r,n=iden,labels=nome)}
if(quad==T) {
	par(pty="m")
}
cat("Banda de ",conf*100,"% de confianca, obtida por ",sim," simulacoes.\n")
}
