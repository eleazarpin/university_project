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
int validarInt(char entero[]);
int validarFloat(char flotante[]);
int validarString(char cadena[]);
int	validarBooleano(char booleano[]);

int longListaId = 0;   //estas variables se usan para ver el balanceo del defvar
int longListaTipos = 0;//estas variables se usan para ver el balanceo del defvar
                     // se van a ir sumando y cuando se ejecuta la regla lv : lt
                     // compara que haya la misma cantidad de los dos lados
int verificarBalanceo();
/* fin de funciones para validacion */

/* funciones para que el bloque DecVar cargue la tabla de símbolos */
char varTypeArray[2][100][50];
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
raiz: programa {    printf("Compila OK \n"); 
                    CrearSymbolTable(symbolTable,"ts.txt");
                    grabarPolaca(); }
    ;

programa:
    bloque_dec sentencias   {   printf("programa: bloque_dec sentencias \n");   }
    | escritura             {   printf("programa: escritura \n");   }
    | bloque_dec            {   printf("programa: bloque_dec \n");  }
    ;

bloque_dec: 
    DEFVAR declaraciones ENDDEF {   consolidateIdType();
                                    printf(" bloque_dec : DEFVAR declaraciones ENDDEF \n ");    }
    ;

declaraciones: 
    declaraciones declaracion    {  printf("declaraciones: declaraciones declaracion \n");  }
    | declaracion                {  printf("declaraciones: declaracion \n");    }
    ;

declaracion:
    lista_variables D_P lista_tipos_datos   {   verificarBalanceo(); 
                                                printf("declaracion: lista_variables D_P lista_tipos_datos \n");    }
    ;

lista_tipos_datos: 
    lista_tipos_datos COMA tipo_dato    {   longListaTipos++; 
                                            printf("\nlista_tipos_datos: lista_tipos_datos COMA tipo_dato \n"); }
    | tipo_dato                         {   longListaTipos++;
                                            printf("\nlista_tipos_datos: tipo_dato \n");    }
    ;

lista_variables: 
    lista_variables COMA ID {   longListaId++; 
                                collectId(yylval.s);
                                printf("\nlista_variables: lista_variables COMA ID: %s\n", yylval.s);   }
    | ID    {   longListaId++;
                collectId(yylval.s);
                printf("lista_variables: ID: %s\n", yylval.s); }
    ;

tipo_dato: 
    STRING      {   collectType("string"); 
                    printf("tipo_dato: STRING \n\n");   }
    | FLOAT     {   collectType("float");
                    printf("tipo_dato: FLOAT \n\n");    }
    | INT       {   collectType("int");
                    printf("tipo_dato: INT \n\n");  }
    | BOOL      {   collectType("bool");
                    printf("tipo_dato: BOOL \n\n"); }
    ;

sentencias: 
    sentencias sentencia    {   printf("sentencias: sentencias sentencia\n");   }
    | sentencia             {   printf("sentencias: sentencia \n"); }
    ;

sentencia: 
    asignacion PUNTO_Y_COMA {   printf("sentencia: asignacion PUNTO_Y_COMA\n"); }
    | iteracion             {   printf("sentencia: iteracion \n");  }
    | decision              {   printf("sentencia: decision \n");   }
    | escritura             {   printf("sentencia: escritura \n");  }
    | lectura               {   printf("sentencia: lectura \n");    }
   	;

decision: 
    IF P_A condicion P_C L_A sentencias L_C {   printf("decision: IF P_A condicion P_C L_A sentencias L_C\n");
                                                desapilarEtiqueta();
                                                strcat(Etiqueta,":");
                                                apilarPolaca(Etiqueta);
                                             }
   | IF P_A condicion P_C L_A sentencias L_C {  printf("fin del then\n");
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
                                                apilarEtiqueta(Etiqueta);   }
    ELSE                                    {   printf("else\n");   }
    L_A sentencias L_C                      {   printf("fin del else\n");
                                                desapilarEtiqueta();
                                                //strcat(EtiqDesa,":");
                                                apilarPolaca(EtiqDesa); }
    | IF P_A condicion P_C L_A  L_C         {   printf("fin del then\n");
                                                generarEtiqueta();//fin
                                                apilarPolaca(Etiqueta);//fin
                                                apilarPolaca("JMP");
                                                desapilarEtiqueta();
                                                strcat(EtiqDesa,":");
                                                apilarPolaca(EtiqDesa);
                                                apilarEtiqueta(Etiqueta);   }
    ELSE                                     {   printf("else\n");   }
    L_A sentencias L_C                      {   printf("fin del else\n");
                                                desapilarEtiqueta();
                                                strcat(EtiqDesa,":");                                           
                                                apilarPolaca(EtiqDesa); }
   ;

iteracion: 
    WHILE   {   printf("while\n");
                generarEtiqueta();//fin
                apilarEtiquetaW(Etiqueta);
                strcat(Etiqueta, ":");
                apilarPolaca(Etiqueta); }
    P_A condicion P_C L_A sentencias L_C    {   printf("\niteracion: WHILE P_A condicion P_C L_A sentencias\n");
                                                desapilarEtiquetaW(); 
                                                apilarPolaca(EtiqDesaW);
                                                apilarPolaca("JMP");
                                                desapilarEtiqueta();
                                                if(auxBool==0){
                                                    printf("PASOOOO 1 \n\n");
                                                    strcat(EtiqDesa,":");
                                                    apilarPolaca(EtiqDesa);
                                                }
                                                else{
                                                    printf("PASOOOO 2 \n\n");
                                                    strcat(auxInlistwhile,":");
                                                    apilarPolaca(auxInlistwhile);
                                                    strcpy(auxInlistwhile, "");
                                                    auxBool=0;
                                                }   }    
    ;

asignacion: 
    ID ASIG expresion           {   printf("asignacion: ID ASIG expresion\n");
                                    auxSymbol = getSymbol($1);
                                    validarTipos(auxSymbol.tipo);
                                    auxSymbol = nullSymbol;
                                    apilarPolaca($1);
                                    apilarPolaca("=");  }
    | ID ASIG concatenacion     {   printf("asignacion: ID ASIG concatenacion\n");
                                    auxSymbol = getSymbol($1);
                                    if(strcmp(auxSymbol.tipo,"string")!=0){ 
                                        auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                    }
                                    //validarTipos("string");
                                    printf("Aca hay que validar asignacion: ID ASIG concatenacion \n");
                                    validarTipos("string");
                                    apilarPolaca($1);
                                    apilarPolaca("=");  }
    ;
    
concatenacion: 
    ID OP_CONCAT ID                  {  auxSymbol = getSymbol($1);
                                        if(strcmp(auxSymbol.tipo,"string")!=0){ 
                                            auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                        }
                                        auxSymbol = getSymbol($3);
                                        if(strcmp(auxSymbol.tipo,"string")!=0){
                                            auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                        }
                                        validarTipos("string");
                                        printf("acá hay que validar concatenacion: ID OP_CONCAT ID");
                                        apilarPolaca($1);
                                        apilarPolaca($3);
                                        apilarPolaca("++"); }
    | ID OP_CONCAT constanteString  {   auxSymbol = getSymbol($1);
                                        if(strcmp(auxSymbol.tipo,"string")!=0){
                                            auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                        }
                                        printf("acá hay que validar concatenacion: ID OP_CONCAT constanteString");
                                        trampearPolaca($1);
                                        validarTipos("string");
                                        apilarPolaca("++"); }
    | constanteString OP_CONCAT ID  {   auxSymbol = getSymbol($3);
                                        if(strcmp(auxSymbol.tipo,"string")!=0){
                                            auxSymbol = nullSymbol; yyerror("Tipos incompatibles");
                                        }
                                        printf("acá hay que validar concatenacion: constanteString OP_CONCAT ID");
                                        validarTipos("string");
                                        apilarPolaca($3);
                                        apilarPolaca("++"); }
    | constanteString OP_CONCAT constanteString {   validarTipos("string");
                                                    apilarPolaca("++");     }
    | constanteString                   {   /*validarTipos("string");*/;    }
    ;

condicion: 
    expresion CMP_MAY expresion     {   printf("condicion  : expresion CMP_MAY expresion \n");
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JNB");    }
    | expresion CMP_MEN expresion   {   printf("condicion  | expresion CMP_MEN expresion \n");
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JNA");    }
    | expresion CMP_MAYI expresion   {  printf("condicion:  \n");
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JNBE");   }
    | expresion CMP_MENI expresion  {   printf("condicion: CMP_MENI expresion   \n");
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JNAE");   }
    | expresion CMP_DIST expresion  {   printf("condicion: CMP_DIST expresion   \n");
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta);
                                        apilarPolaca("JE"); }
    | expresion CMP_IGUAL expresion {   printf("condicion: CMP_IGUAL expresion  \n");
                                        validarTipos("float");
                                        apilarPolaca("CMP");
                                        generarEtiqueta();
                                        apilarEtiqueta(Etiqueta);
                                        apilarPolaca(Etiqueta); 
                                        apilarPolaca("JNZ");    }
    | INLIST P_A ID                 {   //printf("CONDICION: INLIST \n");
                                        //generarEtiqueta();
                                        //printf("ETIQUETA DEL if con INLIST=  %s \n\n\n",Etiqueta);
                                        //apilarPolaca(Etiqueta);
                                        apilarPolaca("_aux"); //creo variable auxiliar para guardar el resultado de 
                                                            //la busqueda de la funcion INLIST
                                        apilarPolaca("0"); 
                                        apilarPolaca("=");
                                        strcpy(auxInlist,$3);
                                        apilarPolaca(auxInlist);    }
    PUNTO_Y_COMA C_A contenido_inlist C_C P_C   {   auxBool=1; 
                                                    //printf("inlist: INLIST P_A ID PUNTO_Y_COMA C_A contenido_inlist C_C P_C\n");
                                                    apilarPolaca("_aux");
                                                    apilarPolaca("1");
                                                    apilarPolaca("CMP");
                                                    generarEtiqueta();
                                                    printf("ETIQUETA if de INLIST=  %s \n\n\n",Etiqueta);
                                                    apilarPolaca(Etiqueta);
                                                    apilarPolaca("JNZ");
                                                    strcpy(auxInlistwhile,Etiqueta);   }
    ;

contenido_inlist: 
    expresion   {   //printf("contenido_inlist: expresion\n");
                    apilarPolaca("CMP");
                    generarEtiqueta();
                    printf("ETIQUETA 1=  %s \n",Etiqueta);
                    apilarPolaca(Etiqueta);
                    apilarPolaca("JNZ");
                    apilarPolaca("_aux"); 
                    apilarPolaca("1"); 
                    apilarPolaca("=");  
                    desapilarEtiqueta();
                    strcat(Etiqueta,":");
                    printf("DESAPILAR ETIQUETA 1=  %s \n",Etiqueta);
                    apilarPolaca(Etiqueta); }

	| contenido_inlist  PUNTO_Y_COMA    {   apilarPolaca(auxInlist);    }
        expresion   {   //printf("contenido_inlist: contenido_inlist PUNTO_Y_COMA expresion\n");
                        apilarPolaca("CMP"); 
                        generarEtiqueta();
                        printf("ETIQUETA 1=  %s \n",Etiqueta);
                        apilarPolaca(Etiqueta);
                        apilarPolaca("JNZ");
                        apilarPolaca("_aux"); 
                        apilarPolaca("1"); 
                        apilarPolaca("=");
                        desapilarEtiqueta();
                        strcat(Etiqueta,":");
                        printf("DESAPILAR ETIQUETA 1=  %s \n",Etiqueta);
                        apilarPolaca(Etiqueta); }
    ;
    
expresion:
    expresion OP_SUM termino        {   printf("expresion: expresion OP_SUM termino \n"); 
                                        validarTipos("float");
                                        apilarPolaca("+");  }
    | expresion OP_RES termino      {   printf("expresion: expresion OP_RES termino\n"); 
                                        validarTipos("float");
                                        apilarPolaca("-");  }
    | termino                       {   printf("expresion: termino  \n");   }
    ;

termino: 
    termino OP_MUL factor       {   printf("termino: termino OP_MUL factor \n"); 
                                    validarTipos("float");
                                    apilarPolaca("*");  }
    | termino OP_DIV factor     {   printf("termino: termino OP_DIV factor \n"); 
                                    validarTipos("float");
                                    apilarPolaca("/");  }
    | termino DIV factor        {   printf("termino: termino DIV factor \n"); 
                                    validarTipos("float");
                                    apilarPolaca("DIV");    }
    | termino MOD factor        {   printf("termino: termino MOD factor \n"); 
                                    validarTipos("float");
                                    apilarPolaca("MOD");    }
    | factor                    {   printf("termino: factor \n");   }
    ;

factor: 
    P_A expresion P_C           {   printf("factor: P_A expresion P_C  \n");    }
    | ID                        {   printf("factor: ID (insertando tipo) \n");
                                    auxSymbol=getSymbol($1);
                                    insertarTipo(auxSymbol.tipo);
                                    printf("Tipo insertado de ID=  %s \n",auxSymbol.tipo);
                                    apilarPolaca($1);   }
    | constanteNumerica
    | avg                       {   printf("factor: avg \n");
                                    sprintf(stringAVG, "%d", contAVG); // replaced itoa(contAVG, stringAVG, 10) for this.
                                    apilarPolaca(stringAVG);
                                    apilarPolaca("/");  }
    ;

avg: 
    AVG P_A C_A contenido_avg C_C P_C   {   printf("avg : AVG P_A C_A contenido_avg C_C P_C \n");   }
	;

contenido_avg: 
    expresion    					{   printf("contenido_avg: expresion ---> Cont:=1 \n ");    }
	| contenido_avg COMA expresion  {   contAVG++; 
                                        printf("contenido_avg: contenido_avg COMA expresion %d \n", contAVG); 
                                        apilarPolaca("+");  }
    ;

constanteNumerica: 
    ENTERO              {   validarInt(yylval.s);
                            printf("constante ENTERO: %s\n", yylval.s);
                            apilarPolaca(yylval.s); }
    | REAL              {   validarFloat(yylval.s);
                            printf("constante REAL: %s\n" , yylval.s);
                            apilarPolaca(yylval.s); }
    | BOOLEANO          {   validarBooleano(yylval.s);
                            printf("constante BOOLEANO: %s\n" , yylval.s); 
                            apilarPolaca(yylval.s); }
    ;
constanteString: 
    STRING_CONST        {   validarString(yylval.s);
                            printf("constante STRING %s\n" , yylval.s);    }
    ;

escritura:
    WRITE expresion PUNTO_Y_COMA        {   printf("escritura: WRITE expresion PUNTO_Y_COMA");
                                            apilarPolaca("WRITE");
                                            resetTipos();   }
    | WRITE concatenacion PUNTO_Y_COMA  {   printf("escritura: WRITE concatenacion PUNTO_Y_COMA");
                                            apilarPolaca("WRITE");
                                            resetTipos();   }
    ;

lectura:
    READ ID PUNTO_Y_COMA    {   printf("lectura: READ ID PUNTO_Y_COMA"); 
                                apilarPolaca("READ");   }
    ;

%%

/* funciones para validacion */
int validarBooleano( char Booleano[]) {
 	char msg[100];
	if (strcmp(Booleano, "true")!= 0 && strcmp(Booleano, "false")!=0){
	    sprintf(msg, "ERROR: %s no es un tipo booleano\n" , Booleano);
        yyerror(msg);
        return 1;
	}
	else{
	//	printf("Booleano ok! %s \n", Booleano);
	    saveSymbol(Booleano,"cBool", NULL);
    	insertarTipo("cBool");
		return 0;
	}		
}

int validarInt(char entero[]){
    int casteado = atoi(entero);
    char msg[100];
    if(casteado < -32768 || casteado > 32767) {
        sprintf(msg, "ERROR: Entero %d fuera de rango. Debe estar entre [-32768; 32767]\n", casteado);
        yyerror(msg);
        return 1;
    }
    else{
        //guardarenTS
        saveSymbol(entero,"cInt", NULL);
        insertarTipo("cInt");

        //printf solo para pruebas:
        //printf("Entero ok! %d \n", casteado);
        return 0;
    }
}

int validarFloat(char flotante[]) {
    double casteado = atof(flotante);
    casteado = fabs(casteado);
    char msg[300];

    if(casteado < FLT_MIN || casteado > FLT_MAX) {
        sprintf(msg, "ERROR: Float %f fuera de rango. Debe estar entre [1.17549e-38; 3.40282e38]\n", casteado);
        yyerror(msg);
        return 1;
    }
    else{
        saveSymbol(flotante,"cFloat", NULL);
        insertarTipo("cFloat");
        // guardarenTS
        // printf solo para pruebas:
        // printf("Float ok! %f \n", casteado);
        return 0;
    }
}

int validarString(char cadena[]) {
    char msg[100];
    int longitud = strlen(cadena);
    if( strlen(cadena) > 32){ //en lugar de 30 verifica con 32 porque el string viene entre comillas
        sprintf(msg, "ERROR: Cadena %s demasiado larga. Maximo 30 caracteres\n", cadena);
        yyerror(msg);
    }
    char sincomillas[31];
    int i;
    for(i=0; i< longitud - 2 ; i++) {
            sincomillas[i]=cadena[i+1];
    }
    sincomillas[i]='\0';
    //guardarenTS();
    saveSymbol(sincomillas,"cString", NULL);
    insertarTipo("string");
    reemplazarBlancos(sincomillas);
    apilarPolaca(sincomillas);
    return 0;
}

int verificarBalanceo(){
    if(longListaTipos != longListaId){
        yyerror("La declaracion de variables debe tener mismo numero de miembros a cada lado del : ");
    }
    longListaTipos = longListaId = 0;
    return 0;
}
/* fin de funciones para validacion */


/* funciones para que el bloque DecVar cargue la tabla de símbolos */
void collectId (char *id) {
    strcpy(varTypeArray[0][idPos++], id);
}

void collectType (char *type){
    strcpy(varTypeArray[1][typePos++], type);
}

void consolidateIdType() {
    printf("Guardando data en tabla de simbolos\n");
    int i;
    for(i=0; i < idPos; i++ ) {
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
    printf("Comparando %s y %s\n",auxa,auxb);
    
    // sino se declaro alguna variable asigno null a tipo
    if (!strcmp(auxa, ""))
     strcpy(auxa,"null");
    
    if (!strcmp(auxb, ""))
     strcpy(auxb,"null");
    
    // Si se agrego algun null salgo
    if(!strcmp(auxa, "null") || !strcmp(auxb, "null") ){
      //     printf("Son iguales\n");
           return 2;
    }
    // si  le asigno a un float un int lo deja pasar
    if ( !strcmp(auxa, "float") && !strcmp(auxb, "cint") ){
        //   printf("Son iguales\n");
           return 0;
    }
    if(!strcmp(auxa, "float") && !strcmp(auxb, "int") ){
       //    printf("Son iguales\n");
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
            sprintf(msg, "Variable no declarada\n");
            yyerror(msg);
        }
        if(compararTipos(tipo,tipos[i])!=0){
            sprintf(msg, "ERROR: Tipos incompatibles\n");
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
        fprintf(stderr,"\nNo se puede abrir el archivo: %s\n", "intermedia.txt");
        exit(1);
    }
    strcpy(nullSymbol.nombre, "!");  // inicializando simbolo nulo
    yyparse();
    // fclose(ArchivoPolaca);
    return 0;
}

void yyerror(char *msg){
    system("cls");
    fprintf(stderr, "At line %d %s \n", yylineno, msg);
    //fprintf(stderr, "At line %d %s in text: %s\n", yylineno, msg, yytext);
    exit(1);
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
