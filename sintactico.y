%{

//=================================================================================
//	Lenguajes y compiladores
// 	Grupo : M3
//	Temas especiales: AVG INLIST
//================================================================================= */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <ctype.h>

extern int yylineno;
extern char *yytext;
FILE *yyin; // Puntero al archivo que se pasa por parametro en el main.
int yylex();
void yyerror(char *msg);


int contAVG=1; // Cantidad de expresiones de la funcion avg
char stringAVG[25]; //guardamos el contador de AVG

char stringBoolInlist[25];
char auxInlistwhile[25]; // usamos para cerrar el while con la funcion INLIST como condicion

char auxInlist[25];
int auxBool=0;

char cteStrSinBlancos[50];
void reemplazarBlancos(char *cad);

/* funciones para polaca etc */
int contEtiqueta = 0;   //para generar etiq unicas
char Etiqueta[10];      //para generar etiq unicas
char EtiqDesa[10];
char EtiqDesaW[10];
char pilaEtiquetas[150][10]; //guarda las etiquetas
int  topeEtiquetas = 0;
char pilaEtiquetasW[150][10]; //guarda las etiquetas
int  topeEtiquetasW = 0;
int  posPolaca = 0;
FILE *ArchivoPolaca;
char buffer[20];
char pilaPolaca[500][50];
int pilaWhile[150];
int topePilaWhile = 0;

void apilarWhile(int pos);
int desapilarWhile();

void apilarPolaca(char *);
void trampearPolaca(char *strToken);
void insertarPolaca(char *s, int p);
void generarEtiqueta();
void apilarEtiqueta(char *strEtiq);
void desapilarEtiqueta();
void apilarEtiquetaW(char *strEtiq);
void desapilarEtiquetaW();
void grabarPolaca();
/* fin de funciones para polaca etc */

/*funciones y estructuras para handle de tipos */
char tipos[20][40];
int contTipos = 0;

int insertarTipo(char tipo[]);
int resetTipos();
int compararTipos(char *a, char *b);
int validarTipos(char tipo[]) ;
/*fin de funciones y estructuras para handle de tipos */


/* funciones tabla de simbolos */
typedef struct symbol {
    char nombre[50];
    char tipo[10];
    char valor[100];
    int longitud;
    int limite;
} symbol;

symbol nullSymbol;
symbol symbolTable[1000];
int pos_st = 0;

// symbolo auxiliar
symbol auxSymbol;
symbol auxSymbol2;
// el valor ! representa al simbolo nulo.


void writeTupla(FILE *p ,int filas,symbol symbolTable[]){
    int j;
    for(j=0; j < filas; j++ ){
        fprintf(p,"%-25s",symbolTable[j].nombre);
        fprintf(p,"|%-25s",symbolTable[j].tipo);
        fprintf(p,"|%-25s",symbolTable[j].valor);
        fprintf(p,"|%-25d",symbolTable[j].longitud);
        fprintf(p,"|%-25d",symbolTable[j].limite);
        fprintf(p, "\n");
    }
}

void writeTable(FILE *p,  int filas, symbol symbolTable[], void (*tupla)(FILE *p ,int filas, symbol symbolTable[])){   
    char titulos[5][20] = {"Nombre","Tipo","Valor","Longitud","Limite"};
    int j;
    for(j=0; j < 5; j++ ){
        if ( j == 0)
           fprintf(p,"%-25s",titulos[j]);
        else
            fprintf(p,"|%-25s",titulos[j]);
    }
    fprintf(p, "\n");
    int i;
    tupla(p,filas,symbolTable);
    fprintf(p,"\n");
}

//Estructura de la SymbolTable
void CrearSymbolTable(symbol symbolTable[],char * ruta){
    //Declaracion de variables
    //Definicion del archivo de salida y su cabecera
    FILE  *p = fopen(ruta, "w");
    writeTable(p,pos_st  , symbolTable,writeTupla);
    //Fin
    fclose(p);
}

// helpers
char *downcase(char *p);
char *prefix_(char *p);
int searchSymbol(char key[]);
int saveSymbol(char nombre[], char tipo[], char valor[] );
symbol getSymbol(char nombre[]);
void symbolTableToExcel(symbol table[],char * ruta);
/* fin de funciones tabla de simbolos */

/* funciones para validacion (cabeceras)*/
/* funciones para validar el rango*/
void guardarIntEnTs(char entero[]);
void guardarFloatEnTs(char flotante[]);
void guardarStringEnTs(char cadena[]);
void guardarBooleanoEnTs(char booleano[]);

/* funciones para que el bloque DecVar cargue la tabla de símbolos */
char varTypeArray[2][100][50]; // Dos matrices de 100 filas y 50 columnas
int idPos = 0;
int typePos = 0;

void collectId (char *id);
void collectType (char *type);
void consolidateIdType();
/* fin de funciones para que el bloque DecVar cargue la tabla de símbolos */

%}

%union{
 char s[20];
}

%token IF ELSE WHILE DEFVAR ENDDEF WRITE READ AVG INLIST
%token REAL BINA ENTERO BOOLEANO STRING_CONST
%token <s> ID
%token FLOAT INT STRING BOOL
%token P_A P_C C_A C_C L_A L_C PUNTO_Y_COMA D_P COMA
%token OP_CONCAT OP_SUM OP_RES OP_DIV OP_MUL MOD DIV 
%token CMP_MAY CMP_MEN CMP_MAYI CMP_MENI CMP_DIST CMP_IGUAL
%token ASIG
%type <s> expresion

%%
raiz: programa {    fprintf(stdout,"\nCompila OK\n\n"); 
                    fflush(stdout);
                    CrearSymbolTable(symbolTable,"ts.txt");
                    grabarPolaca(); }
    ;

programa:
    bloque_dec sentencias   {   fprintf(stdout,"\nprograma - bloque_dec sentencias");
                                fflush(stdout); }
    | bloque_escritura             {   fprintf(stdout,"\nprograma - escritura");   
                                fflush(stdout); }
    | bloque_dec            {   fprintf(stdout,"\nprograma - bloque_dec");  
                                fflush(stdout); }
    ;

bloque_escritura: 
    escritura                       {   fprintf(stdout,"\nbloque_escritura - escritura");
                                        fflush(stdout); }
    | bloque_escritura escritura    {   fprintf(stdout,"\nbloque_escritura - bloque_escritura escritura");
                                        fflush(stdout); }
    ;

bloque_dec: 
    DEFVAR declaraciones ENDDEF {   fprintf(stdout,"\nbloque_dec - DEFVAR declaraciones ENDDEF");    
                                    fflush(stdout); }
    ;

declaraciones: 
    declaraciones declaracion    {  fprintf(stdout,"\ndeclaraciones - declaraciones declaracion");  
                                    fflush(stdout); }
    | declaracion                {  fprintf(stdout,"\ndeclaraciones - declaracion");
                                    fflush(stdout); }
    ;

declaracion:
    lista_variables D_P tipo_dato   {   fprintf(stdout,"\ndeclaracion - lista_variables D_P tipo_dato");    
                                        fflush(stdout); }
    ;

lista_variables: 
    lista_variables COMA ID {   collectId(yylval.s);
                                fprintf(stdout,"\nlista_variables - lista_variables COMA ID: %s", yylval.s);   
                                fflush(stdout); }
    | ID    {   collectId(yylval.s);
                fprintf(stdout,"\nlista_variables - ID: %s", yylval.s);
                fflush(stdout); }
    ;

tipo_dato: 
    STRING      {   collectType("string"); 
                    fprintf(stdout,"\ntipo_dato - STRING");   
                    fflush(stdout); 
                    consolidateIdType();    }
    | FLOAT     {   collectType("float");
                    fprintf(stdout,"\ntipo_dato - FLOAT");
                    fflush(stdout); 
                    consolidateIdType();    }
    | INT       {   collectType("int");
                    fprintf(stdout,"\ntipo_dato - INT"); 
                    fflush(stdout); 
                    consolidateIdType();    }
    | BOOL      {   collectType("bool");
                    fprintf(stdout,"\ntipo_dato - BOOL"); 
                    fflush(stdout); 
                    consolidateIdType();    }
    ;

sentencias: 
    sentencias sentencia    {   fprintf(stdout,"\nsentencias - sentencias sentencia");   
                                fflush(stdout); }
    | sentencia             {   fprintf(stdout,"\nsentencias - sentencia"); 
                                fflush(stdout); }
    ;

sentencia: 
    asignacion PUNTO_Y_COMA {   fprintf(stdout,"\nsentencia - asignacion PUNTO_Y_COMA"); 
                                fflush(stdout); }
    | iteracion             {   fprintf(stdout,"\nsentencia - iteracion");  
                                fflush(stdout); }
    | decision              {   fprintf(stdout,"\nsentencia - decision");   
                                fflush(stdout); }
    | escritura             {   fprintf(stdout,"\nsentencia - escritura");  
                                fflush(stdout); }
    | lectura               {   fprintf(stdout,"\nsentencia - lectura");    
                                fflush(stdout); }
   	;

decision: 
    IF P_A condicion P_C L_A sentencias L_C {   fprintf(stdout,"\ndecision - IF P_A condicion P_C L_A sentencias L_C");
                                                fflush(stdout);
                                                fprintf(stdout,"\nInicio del then");
                                                fflush(stdout);
                                                desapilarEtiqueta();
                                                strcat(Etiqueta,":");
                                                apilarPolaca(Etiqueta);
                                                fprintf(stdout,"\nFin del then");   
                                                fflush(stdout); }
   | IF P_A condicion P_C L_A sentencias L_C {  fprintf(stdout,"\ndecision - IF P_A condicion P_C L_A sentencias L_C");
                                                fflush(stdout);
                                                fprintf(stdout,"\nInicio del then");
                                                fflush(stdout);
                                                strcpy(auxInlist,Etiqueta);
                                                strcat(auxInlist,":");
                                                generarEtiqueta();
                                                apilarPolaca(Etiqueta);
                                                apilarPolaca("JMP");
                                                apilarPolaca(auxInlist);
                                                desapilarEtiqueta();
                                                strcat(Etiqueta,":");
                                                // aca esta la magia
                                                // aca termina la magia 
                                                apilarEtiqueta(Etiqueta);
                                                fprintf(stdout,"\nFin del then");
                                                fflush(stdout); }
    ELSE                                    {   fprintf(stdout,"\nInicio del else");
                                                fflush(stdout);   }
    L_A sentencias L_C                      {   fprintf(stdout,"\nFin del else");
                                                fflush(stdout);
                                                desapilarEtiqueta();
                                                //strcat(EtiqDesa,":");
                                                apilarPolaca(EtiqDesa); }
    | IF P_A condicion P_C L_A  L_C         {   fprintf(stdout,"\nFin del then");
                                                fflush(stdout);
                                                generarEtiqueta();//fin
                                                apilarPolaca(Etiqueta);//fin
                                                apilarPolaca("JMP");
                                                desapilarEtiqueta();
                                                strcat(EtiqDesa,":");
                                                apilarPolaca(EtiqDesa);
                                                apilarEtiqueta(Etiqueta);   }
    ELSE                                    {   fprintf(stdout,"\nelse");
                                                fflush(stdout); }
    L_A sentencias L_C                      {   fprintf(stdout,"\nfin del else");
                                                fflush(stdout);
                                                desapilarEtiqueta();
                                                strcat(EtiqDesa,":");                                           
                                                apilarPolaca(EtiqDesa); }
   ;

iteracion: 
    WHILE   {   fprintf(stdout,"\niteracion - WHILE");
                fflush(stdout);
                generarEtiqueta();//fin
                apilarEtiquetaW(Etiqueta);
                strcat(Etiqueta, ":");
                apilarPolaca(Etiqueta); }
    P_A condicion P_C L_A sentencias L_C    {   fprintf(stdout,"\niteracion - P_A condicion P_C L_A sentencias");
                                                fflush(stdout);
                                                desapilarEtiquetaW(); 
                                                apilarPolaca(EtiqDesaW);
                                                apilarPolaca("JMP");
                                                desapilarEtiqueta();
                                                if(auxBool==0){
                                                    fprintf(stdout,"\nPASO 1");
                                                    fflush(stdout);
                                                    strcat(EtiqDesa,":");
                                                    apilarPolaca(EtiqDesa);
                                                }
                                                else{
                                                    fprintf(stdout,"\nPASO 2");
                                                    fflush(stdout);
                                                    strcat(auxInlistwhile,":");
                                                    apilarPolaca(auxInlistwhile);
                                                    strcpy(auxInlistwhile, "");
                                                    auxBool=0;
                                                }   }    
    ;

asignacion: 
    ID ASIG expresion           {   fprintf(stdout,"\nasignacion - ID ASIG expresion");
                                    fflush(stdout);
                                    auxSymbol = getSymbol($1);
                                    validarTipos(auxSymbol.tipo);
                                    auxSymbol = nullSymbol;
                                    apilarPolaca($1);
                                    apilarPolaca("=");  }
    | ID ASIG concatenacion     {   fprintf(stdout,"\nasignacion - ID ASIG concatenacion");
                                    fflush(stdout);
                                    auxSymbol = getSymbol($1);
                                    if(strcmp(auxSymbol.tipo,"string")!=0){ 
                                        auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                    }
                                    //validarTipos("string");
                                    fprintf(stdout,"\nAca hay que validar asignacion: ID ASIG concatenacion");
                                    fflush(stdout);
                                    validarTipos("string");
                                    apilarPolaca($1);
                                    apilarPolaca("=");  }
    ;
    
concatenacion: 
    ID OP_CONCAT ID                  {  fprintf(stdout,"\nconcatenacion - ID OP_CONCAT ID");
                                        fflush(stdout);
                                        auxSymbol = getSymbol($1);
                                        if(strcmp(auxSymbol.tipo,"string")!=0){ 
                                            auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                        }
                                        auxSymbol = getSymbol($3);
                                        if(strcmp(auxSymbol.tipo,"string")!=0){
                                            auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                        }
                                        validarTipos("string");
                                        fprintf(stdout,"\nacá hay que validar concatenacion: ID OP_CONCAT ID");
                                        fflush(stdout);
                                        apilarPolaca($1);
                                        apilarPolaca($3);
                                        apilarPolaca("++"); }
    | ID OP_CONCAT constanteString  {   fprintf(stdout,"\nconcatenacion - ID OP_CONCAT constanteString");
                                        fflush(stdout);
                                        auxSymbol = getSymbol($1);
                                        if(strcmp(auxSymbol.tipo,"string")!=0){
                                            auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                        }
                                        fprintf(stdout,"\nacá hay que validar concatenacion: ID OP_CONCAT constanteString");
                                        trampearPolaca($1);
                                        validarTipos("string");
                                        apilarPolaca("++"); }
    | constanteString OP_CONCAT ID  {   fprintf(stdout,"\nconcatenacion - constanteString OP_CONCAT ID");
                                        fflush(stdout);
                                        auxSymbol = getSymbol($3);
                                        if(strcmp(auxSymbol.tipo,"string")!=0){
                                            auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                        }
                                        fprintf(stdout,"\nacá hay que validar concatenacion: constanteString OP_CONCAT ID");
                                        fflush(stdout);
                                        validarTipos("string");
                                        apilarPolaca($3);
                                        apilarPolaca("++"); }
    | constanteString OP_CONCAT constanteString {   fprintf(stdout,"\nconcatenacion - constanteString OP_CONCAT constanteString");
                                                    fflush(stdout);
                                                    validarTipos("string");
                                                    apilarPolaca("++");     }
    | constanteString                   {   fprintf(stdout,"\nconcatenacion - constanteString");
                                            fflush(stdout);
                                            /*validarTipos("string");*/ }
    ;

condicion: 
    expresion CMP_MAY expresion     {   fprintf(stdout,"\ncondicion - expresion CMP_MAY expresion");
                                        fflush(stdout);
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JNB");    }
    | expresion CMP_MEN expresion   {   fprintf(stdout,"\ncondicion - expresion CMP_MEN expresion");
                                        fflush(stdout);
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JNA");    }
    | expresion CMP_MAYI expresion   {  fprintf(stdout,"\ncondicion - expresion CMP_MAYI expresion");
                                        fflush(stdout);
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JNBE");   }
    | expresion CMP_MENI expresion  {   fprintf(stdout,"\ncondicion - expresion CMP_MENI expresion");
                                        fflush(stdout);
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JNAE");   }
    | expresion CMP_DIST expresion  {   fprintf(stdout,"\ncondicion - expresion CMP_DIST expresion");
                                        fflush(stdout);
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JE"); }
    | expresion CMP_IGUAL expresion {   fprintf(stdout,"\ncondicion - expresion CMP_IGUAL expresion");
                                        fflush(stdout);
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta); 
                                        apilarPolaca("JNZ");    }
    | INLIST P_A ID                 {   fprintf(stdout,"\ncondicion - INLIST P_A ID");
                                        fflush(stdout);
                                        //fprintf(stdout,"CONDICION: INLIST \n");
                                        //generarEtiqueta();
                                        //fprintf(stdout,"ETIQUETA DEL if con INLIST=  %s \n\n\n",Etiqueta);
                                        //apilarPolaca(Etiqueta);
                                        apilarPolaca("_aux"); //creo variable auxiliar para guardar el resultado de 
                                                            //la busqueda de la funcion INLIST
                                        apilarPolaca("0"); 
                                        apilarPolaca("=");
                                        strcpy(auxInlist,$3);
                                        apilarPolaca(auxInlist);    }
    PUNTO_Y_COMA C_A contenido_inlist C_C P_C   {   fprintf(stdout,"\ncondicion - PUNTO_Y_COMA C_A contenido_inlist C_C P_C");
                                                    fflush(stdout);
                                                    auxBool=1; 
                                                    //fprintf(stdout,"inlist: INLIST P_A ID PUNTO_Y_COMA C_A contenido_inlist C_C P_C\n");
                                                    apilarPolaca("_aux");
                                                    apilarPolaca("1");
                                                    apilarPolaca("CMP");
                                                    generarEtiqueta();
                                                    fprintf(stdout,"\nETIQUETA if de INLIST=  %s:",Etiqueta);
                                                    fflush(stdout);
                                                    apilarPolaca(Etiqueta);
                                                    apilarPolaca("JNZ");
                                                    strcpy(auxInlistwhile,Etiqueta);   }
    ;

contenido_inlist: 
    expresion   {   fprintf(stdout,"\ncontenido_inlist - expresion");
                    fflush(stdout);
                    apilarPolaca("CMP");
                    generarEtiqueta();
                    fprintf(stdout,"\nETIQUETA 1 =  %s",Etiqueta);
                    apilarPolaca(Etiqueta);
                    apilarPolaca("JNZ");
                    apilarPolaca("_aux"); 
                    apilarPolaca("1"); 
                    apilarPolaca("=");  
                    desapilarEtiqueta();
                    strcat(Etiqueta,":");
                    fprintf(stdout,"\nDESAPILAR ETIQUETA 1=  %s",Etiqueta);
                    apilarPolaca(Etiqueta); }

	| contenido_inlist  PUNTO_Y_COMA    {   fprintf(stdout,"contenido_inlist - contenido_inlist PUNTO_Y_COMA expresion\n");
                                            fflush(stdout);
                                            apilarPolaca(auxInlist);    }
        expresion   {   //fprintf(stdout,"contenido_inlist: contenido_inlist PUNTO_Y_COMA expresion\n");
                        apilarPolaca("CMP"); 
                        generarEtiqueta();
                        fprintf(stdout,"\nETIQUETA 1=  %s",Etiqueta);
                        fflush(stdout);
                        apilarPolaca(Etiqueta);
                        apilarPolaca("JNZ");
                        apilarPolaca("_aux"); 
                        apilarPolaca("1"); 
                        apilarPolaca("=");
                        desapilarEtiqueta();
                        strcat(Etiqueta,":");
                        fprintf(stdout,"\nDESAPILAR ETIQUETA 1=  %s",Etiqueta);
                        fflush(stdout);
                        apilarPolaca(Etiqueta); }
    ;
    
expresion:
    expresion OP_SUM termino        {   fprintf(stdout,"\nexpresion - expresion OP_SUM termino"); 
                                        fflush(stdout);
                                        validarTipos("float");
                                        apilarPolaca("+");  }
    | expresion OP_RES termino      {   fprintf(stdout,"\nexpresion - expresion OP_RES termino"); 
                                        validarTipos("float");
                                        apilarPolaca("-");  }
    | termino                       {   fprintf(stdout,"\nexpresion - termino");   }
    ;

termino: 
    termino OP_MUL factor       {   fprintf(stdout,"\ntermino - termino OP_MUL factor"); 
                                    fflush(stdout);
                                    validarTipos("float");
                                    apilarPolaca("*");  }
    | termino OP_DIV factor     {   fprintf(stdout,"\ntermino - termino OP_DIV factor"); 
                                    fflush(stdout);
                                    validarTipos("float");
                                    apilarPolaca("/");  }
    | termino DIV factor        {   fprintf(stdout,"\ntermino - termino DIV factor"); 
                                    fflush(stdout);
                                    validarTipos("float");
                                    apilarPolaca("DIV");    }
    | termino MOD factor        {   fprintf(stdout,"\ntermino - termino MOD factor"); 
                                    fflush(stdout);
                                    validarTipos("float");
                                    apilarPolaca("MOD");    }
    | factor                    {   fprintf(stdout,"\ntermino - factor");
                                    fflush(stdout);   }
    ;

factor: 
    P_A expresion P_C           {   fprintf(stdout,"\nfactor - P_A expresion P_C");
                                    fflush(stdout); }
    | ID                        {   fprintf(stdout,"\nfactor - ID (insertando tipo)");
                                    fflush(stdout);
                                    auxSymbol=getSymbol($1);
                                    insertarTipo(auxSymbol.tipo);
                                    fprintf(stdout,"\nTipo insertado de ID=  %s",auxSymbol.tipo);
                                    fflush(stdout);
                                    apilarPolaca($1);   }
    | constanteNumerica         {   fprintf(stdout,"\nfactor - constanteNumerica");
                                    fflush(stdout); }
    | avg                       {   fprintf(stdout,"\nfactor - avg");
                                    fflush(stdout);
                                    sprintf(stringAVG, "%d", contAVG); // replaced itoa(contAVG, stringAVG, 10) for this.
                                    apilarPolaca(stringAVG);
                                    apilarPolaca("/");  }
    ;

avg: 
    AVG P_A C_A contenido_avg C_C P_C   {   fprintf(stdout,"\navg - AVG P_A C_A contenido_avg C_C P_C");
                                            fflush(stdout); }
	;

contenido_avg: 
    expresion    					{   fprintf(stdout,"\ncontenido_avg - expresion ---> Cont:=1");
                                        fflush(stdout); }
	| contenido_avg COMA expresion  {   contAVG++; 
                                        fprintf(stdout,"\ncontenido_avg - contenido_avg COMA expresion %d", contAVG); 
                                        fflush(stdout);
                                        apilarPolaca("+");  }
    ;

constanteNumerica: 
    ENTERO              {   guardarIntEnTs(yylval.s);
                            fprintf(stdout,"\nconstante - ENTERO: %s", yylval.s);
                            fflush(stdout);
                            apilarPolaca(yylval.s); }
    | REAL              {   guardarFloatEnTs(yylval.s);
                            fprintf(stdout,"\nconstante - REAL: %s" , yylval.s);
                            fflush(stdout);
                            apilarPolaca(yylval.s); }
    | BOOLEANO          {   guardarBooleanoEnTs(yylval.s);
                            fprintf(stdout,"\nconstante - BOOLEANO: %s" , yylval.s); 
                            fflush(stdout);
                            apilarPolaca(yylval.s); }
    ;
constanteString: 
    STRING_CONST        {   guardarStringEnTs(yylval.s);
                            fprintf(stdout,"\nconstante - STRING %s" , yylval.s);
                            fflush(stdout); }
    ;

escritura:
    WRITE expresion PUNTO_Y_COMA        {   fprintf(stdout,"\nescritura - WRITE expresion PUNTO_Y_COMA");
                                            fflush(stdout);
                                            apilarPolaca("WRITE");
                                            resetTipos();   }
    | WRITE concatenacion PUNTO_Y_COMA  {   fprintf(stdout,"\nescritura - WRITE concatenacion PUNTO_Y_COMA");
                                            fflush(stdout);
                                            apilarPolaca("WRITE");
                                            resetTipos();   }
    ;

lectura:
    READ ID PUNTO_Y_COMA    {   fprintf(stdout,"\nlectura - READ ID PUNTO_Y_COMA"); 
                                fflush(stdout);
                                apilarPolaca("READ");   }

    ;
%%

/* funciones para validacion */
void guardarBooleanoEnTs(char Booleano[]) {
    saveSymbol(Booleano,"cBool", NULL);
    insertarTipo("cBool");		
}

void guardarIntEnTs(char entero[]) {
    saveSymbol(entero,"cInt", NULL);
    insertarTipo("cInt");
}

void guardarFloatEnTs(char flotante[]) {
    saveSymbol(flotante,"cFloat", NULL);
    insertarTipo("cFloat");
}

void guardarStringEnTs(char cadena[]) {
    char sincomillas[31];
    int longitud = strlen(cadena);
    int i;
    for(i=0; i<longitud - 2 ; i++) {
            sincomillas[i]=cadena[i+1];
    }
    sincomillas[i]='\0';
    saveSymbol(sincomillas,"cString", NULL);
    insertarTipo("string");
    reemplazarBlancos(sincomillas);
    apilarPolaca(sincomillas);
}

/* funciones para que el bloque DecVar cargue la tabla de símbolos */
void collectId (char *id) {
    strcpy(varTypeArray[0][idPos++], id);
}

void collectType (char *type){
    strcpy(varTypeArray[1][typePos++], type);
}

void consolidateIdType() {
    int i;
    for(i=0; i < idPos; i++) {
        saveSymbol(varTypeArray[0][i],varTypeArray[1][i], NULL);
    }
    idPos=0;
    typePos=0;
}
/* fin de funciones para que el bloque DecVar cargue la tabla de símbolos */

/* funciones tabla de simbolos */
char *downcase(char *p){
    char *pOrig = p;
    for ( ; *p; ++p) *p = tolower(*p);
    return pOrig;
}

char *prefix_(char *p){
    int tam = strlen(p);
    p = p + tam ;
    int i;
    for(i=0; i < tam + 1 ; i++){
        *(p+1) = *p;
        p--;
    }
    *(p+1) = '_';
    return p+1;
}

int searchSymbol(char key[]){
    static int llamada=0;
    llamada++;
    char mynombre[100];
    strcpy(mynombre,key);
    prefix_(downcase(mynombre));
    int i;
    for ( i = 0;  i < pos_st ; i++) {
        if(strcmp(symbolTable[i].nombre, mynombre) == 0){
            return i;
        }
    }
    return -1;
}

int saveSymbol(char nombre[], char tipo[], char valor[] ){
    char mynombre[100];
    char type[10];
    strcpy(type,tipo);
    strcpy(mynombre,nombre);
    downcase(type);
    int use_pos = searchSymbol(nombre);
    if ( use_pos == -1){
        use_pos = pos_st;
        pos_st++;
    }
    symbol newSymbol;
    strcpy(newSymbol.nombre, prefix_(downcase(mynombre)));
    strcpy(newSymbol.tipo, type);
    if (valor == NULL){
        strcpy(newSymbol.valor, nombre);
    }
    else{
        strcpy(newSymbol.valor, valor);
    }
    newSymbol.longitud = strlen(nombre);
    symbolTable[use_pos] = newSymbol;
    newSymbol = nullSymbol;
    return 0;
}

symbol getSymbol(char nombre[]){
    int pos = searchSymbol(nombre);
    if(pos >= 0) return symbolTable[pos];
    return nullSymbol;
}

void symbolTableToExcel(symbol table[],char * ruta){
    //Declaracion de variables
    int i;
    //Definicion del archivo de salida y su cabecera
    FILE  *ptr = fopen(ruta, "w");
    fprintf(ptr,"nombre,tipo,valor,longitud,limite\n");
    for(i=0;i < pos_st ;i++) {
        fprintf(ptr, "%s,%s,%s,%d,%d\n",table[i].nombre,table[i].tipo,table[i].valor,table[i].longitud,table[i].limite);
    }
    //Fin
    fclose(ptr);
}
/* fin de funciones tabla de simbolos */

/*funciones  para handle de tipos */
int insertarTipo(char tipo[]) {
    strcpy(tipos[contTipos],tipo);
    strcpy(tipos[contTipos+1],"null");
    contTipos++;
    return 0;
}

int resetTipos(){
    contTipos = 0;
    strcpy(tipos[contTipos],"null");
    return 0;
}

int compararTipos(char *a, char *b){
    char auxa[50];
    char auxb[50];
    strcpy(auxa,a);
    strcpy(auxb,b);
    downcase(auxa);
    downcase(auxb);
    // fprintf(stdout,"Comparando %s y %s",auxa,auxb);
    // fflush(stdout);
    
    // sino se declaro alguna variable asigno null a tipo
    if (!strcmp(auxa, ""))
     strcpy(auxa,"null");
    
    if (!strcmp(auxb, ""))
     strcpy(auxb,"null");
    
    // Si se agrego algun null salgo
    if(!strcmp(auxa, "null") || !strcmp(auxb, "null") ){
      //     fprintf(stdout,"Son iguales\n");
           return 2;
    }
    // si  le asigno a un float un int lo deja pasar
    if ( !strcmp(auxa, "float") && !strcmp(auxb, "cint") ){
        //   fprintf(stdout,"Son iguales\n");
           return 0;
    }
    if(!strcmp(auxa, "float") && !strcmp(auxb, "int") ){
       //    fprintf(stdout,"Son iguales\n");
           return 0;
    }
    if (strstr(auxa,auxb) != NULL){
        return 0;
    }
    if (strstr(auxb,auxa) != NULL){
        return 0;
    }
    return 1;
}

int validarTipos(char tipo[]) {
    char msg[100];
    int i;
    for(i=0; i< contTipos; i++){
        if(compararTipos(tipo,tipos[i])==2){
            sprintf(msg, "Variable no declarada");
            yyerror(msg);
        }
        if(compararTipos(tipo,tipos[i])!=0){
            sprintf(msg, "Tipos incompatibles");
            yyerror(msg);
        }
    }
    resetTipos();
    return 0;
}
/*fin de funciones  para handle de tipos */

/***************************************************
funcion que genera la polaca en el archivo intermedia.txt
***************************************************/
void apilarPolaca(char *strToken){
        strcpy(pilaPolaca[posPolaca],strToken);
        //fprintf(ArchivoPolaca, "%d : %s\n", posPolaca, strToken);
        posPolaca++;
   	/*if (c != EOF )
			fprintf(ArchivoPolaca, ",");*/
}

void trampearPolaca(char *strToken){
    strcpy(pilaPolaca[posPolaca],pilaPolaca[posPolaca-1]);
    strcpy(pilaPolaca[posPolaca-1],strToken);
    posPolaca++;
}

void insertarPolaca(char *strToken, int pos){
    strcpy(pilaPolaca[pos],strToken);
}

void grabarPolaca(){
    int i;
    for(i=0; i<posPolaca ; i++){
        fprintf(ArchivoPolaca, "%s\n",pilaPolaca[i]);
    }
    fclose(ArchivoPolaca);
}

/***************************************************
funcion que genera etiquetas unicas
***************************************************/
void generarEtiqueta(){
    char string[25];
  	strcpy(Etiqueta,"@@etiq");
	contEtiqueta = contEtiqueta + 1;
    sprintf(string, "%d", contEtiqueta); // replaced itoa(contEtiqueta, string, 10)  for this.
    strcat(Etiqueta, string);
}

/***************************************************
funcion que guarda en la pila una etiqueta
***************************************************/
void apilarEtiqueta(char *strEtiq){
    strcpy(pilaEtiquetas[topeEtiquetas],strEtiq);
    topeEtiquetas = topeEtiquetas + 1;
}

void apilarEtiquetaW(char *strEtiq){
    strcpy(pilaEtiquetasW[topeEtiquetasW],strEtiq);
    topeEtiquetasW++;
}

void apilarWhile(int pos){
    pilaWhile[topePilaWhile]=pos;
    topePilaWhile++;
}

int desapilarWhile(){
    topePilaWhile--;
    return(pilaWhile[topePilaWhile]);
}

/***************************************************
funcion que saca de la pila una etiqueta
***************************************************/
void desapilarEtiqueta(){

    topeEtiquetas = topeEtiquetas - 1;
    strcpy(EtiqDesa,pilaEtiquetas[topeEtiquetas]);
	strcpy(pilaEtiquetas[topeEtiquetas],"");
}

void desapilarEtiquetaW(){

    topeEtiquetasW--;
    strcpy(EtiqDesaW,pilaEtiquetasW[topeEtiquetasW]);
	strcpy(pilaEtiquetasW[topeEtiquetasW],"");
}
/* fin de funciones para polaca */

int main(int argc,  char *argv[]){
    if ((ArchivoPolaca = fopen("intermedia.txt", "wt")) == NULL) {
        fprintf(stderr,"\nNo se puede crear el archivo: %s", "intermedia.txt");
        exit(1);
    }
    if ((yyin = fopen(argv[1], "rt")) == NULL){
	    fprintf(stderr, "\nNo se puede abrir el archivo: %s", argv[1]);
        exit(1);
	}
    strcpy(nullSymbol.nombre, "!");  // inicializando simbolo nulo
    yyparse();
    fclose(ArchivoPolaca);
    fclose(yyin);
    return 0;
}

void yyerror(char *msg){
    fflush(stderr);
    fprintf(stderr, "\n\n--- ERROR ---\nAt line %d: \'%s\'.\n\n", yylineno, msg);
    exit(1);
}

void imprimirPorConsola(char *str){
    fflush(stdout);
}

void reemplazarBlancos(char *cad){
	int i,num;
	char aux[50];
	for(i=0; i < strlen(cad); i++){
		if((cad[i]=='_') || cad[i]=='\0' || cad[i]=='\n' || (cad[i]>='0' &&cad[i]<='9') || (cad[i]>='a' && cad[i]<= 'z')|| (cad[i]>= 'A' &&cad[i]<='Z')){
			cteStrSinBlancos[i]=cad[i];
        }
		else{
		    cteStrSinBlancos[i]='_';
        }
	}
	cteStrSinBlancos[i--]='\0';
	strcpy(cad,cteStrSinBlancos);
}
