// CSC1401 project

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <stdlib.h>

char Username[100][50], fname[100][50], lname[100][50], dateOfBirth[100][50], password[100][50], encPassword[100][50];
int age[100];
int count = 0;


void menu1();
void menu2();
int contains(char a[]);
int checkPass(char a[],int b);
int validPass(char a[]);
void swap(char *str1, char *str2);
void encrypte(char a[]);
void decrypte(char a[]);
void swapAge(int *str1, int *str2);
int computeAge(char a[]);
int maxi(int a, int b);
int LCS( char *X, char *Y, int m, int n );
int cmpfunc (const void * a, const void * b);

int main() {
    char pass[50],user[50],temp[200],ftemp[50],ltemp[50];
	char newPass[50],newUser[50],newFName[50],newLName[50],newBirthDate[50];
    int choice,i,choice2,l,L, k,j,temp1,tokenCount,account;
	char temp2[50];
    //const char s[2] = "-";
	char *token;
		   
    FILE *database;
    //inp = fopen("inp.txt","r");
    //out = fopen("out.txt","w");
    
    database = fopen("database.txt", "r");
    
	
   while(fgets(temp,200,database) != NULL){
    	
		L = strlen(temp);
		temp[L-1] = '\0';
    	//printf("%d - %s",count, temp);
		for(i = 0; i<strlen(temp);i++)
			if(temp[i] == '\t')
				temp[i] = ' ';
		//s[2] = "-";
		
		/* get the first token */
		token = strtok(temp," ");
		tokenCount = 0;   
		/* walk through other tokens */
		while( token != NULL ) 
		{
			//printf( " %s\n", token );
			if(tokenCount == 0){
				strcpy(Username[count],token);
				token = strtok(NULL, " ");
			}else if(tokenCount == 1){
				strcpy(fname[count],token);
				token = strtok(NULL, " ");
			}else if(tokenCount == 2){
				strcpy(lname[count],token);
				token = strtok(NULL, " ");
			}else if(tokenCount == 3){
				age[count] = computeAge(token);
				strcpy(dateOfBirth[count],token);
				token = strtok(NULL, " ");
			}else{
				strcpy(password[count],token);
				encrypte(token);
				strcpy(encPassword[count],token);
				token = strtok(NULL, " ");
			}
			
			
			tokenCount++;
		}
		count++;
    }
    fclose(database);
	
    do{
		menu1();
    	printf("\n Please enter your choice. ");
	    scanf("%d", &choice);
	    
	    switch(choice){
			case 1:
				printf("\n please enter Username: ");
				scanf(" %s",user);
				printf("\n please enter password: ");
				scanf(" %s",pass);
				account = contains(user);
				
				if(account>=0){
					if(checkPass(pass,account)){
						//log in
						do{
							printf("\n Welcome Mr./Mrs. :");
							printf("\n First name: %s",fname[account]);
							printf("\n Last name : %s",lname[account]);
							printf("\n Age : %d",age[account]);
							menu2();
							printf("\n Please enter your choice. ");
							scanf("%d", &choice2);
							switch(choice2){
								case 1:
									do{
										printf("\nEnter new username: ");
										scanf(" %s", newUser);
										if(contains(newUser)==-1)
											break;
										else
											printf("\nUsername already exists.");
									}while(1);
									strcpy(Username[account],newUser);
									break;
									
								case 2:
									do{
										printf("\nEnter new password: ");
										scanf(" %s", newPass);
										if(validPass(newPass))
											break;
										else
											printf("\nThe password should respect the following format: \n > 12 characters that must include \n > 3 lowercase letters\n > 3 uppercase letters\n > 3 digits\n > 3 other characters that are not digits and not letters not (@, %c , ;)\n",'\\');
									}while(1);
									strcpy(password[account],newPass);
									encrypte(newPass);
									strcpy(encPassword[account],newPass);
									break;
								case 3:
									//logout
									printf("\nThanks for using our platform :)");
									break;
							}
						}while(choice2 != 3);
					}else{
						printf("\nInvalid password!");
					}
						
				}else{
					printf("\nInvalid username");
				}
				
				break;
			case 2:
				printf("\n please enter a Username: ");
				scanf(" %s",temp);
				while(1){
					if(contains(temp) == -1){
						strcpy(Username[count],temp);
						break;
					}
					printf("\nPlease enter a different Username: ");
					scanf(" %s",temp);
						
				}
				
				printf("\n please enter fname: ");
				scanf(" %s",fname[count]);
				printf("\n please enter lname: ");
				scanf(" %s",lname[count]);
				printf("\n please enter date of birth: ");
				scanf(" %s",dateOfBirth[count]);
				age[count] = computeAge(dateOfBirth[count]);
				do{
					printf("\n please enter password: ");
					scanf(" %s", newPass);
					if(validPass(newPass))
						break;
					else
						printf("\nThe password should respect the following format: \n > 12 characters that must include \n > 3 lowercase letters\n > 3 uppercase letters\n > 3 digits\n > 3 other characters that are not digits and not letters and not (@ , %c , ; )\n",'\\');
				}while(1);
				strcpy(password[count],newPass);
				encrypte(newPass);
				strcpy(encPassword[count],newPass);
				count++;
				break;
			case 3:
				//quit
				
				
				database = fopen("output.txt", "a");
				
				//sort elements
				for(i = 0; i<count;i++)
					for(j =0; j<count-1;j++){
						
						if(age[j]<age[j+1]){
						
							//swap(Username[j],Username[j+1]);
							strcpy(temp2,Username[j]);
							strcpy(Username[j] , Username[j+1]);
							strcpy(Username[j+1] , temp2);
							//swap(fname[j],fname[j+1]);
							strcpy(temp2 , fname[j]);
							strcpy(fname[j] , fname[j+1]);
							strcpy(fname[j+1] , temp2);
							//swap(lname[j],lname[j+1]);
							strcpy(temp2 ,lname[j]);
							strcpy(lname[j] , lname[j+1]);
							strcpy(lname[j+1] , temp2);
							//swap(password[j],password[j+1]);
							strcpy(temp2 , password[j]);
							strcpy(password[j] , password[j+1]);
							strcpy(password[j+1] , temp2);
							//swapAge(&age[j],&age[j+1]);
							temp1 = age[j];
							age[j] = age[j+1];
							age[j+1] = temp1;
							//swap(dateOfBirth[j],dateOfBirth[j+1]);
							strcpy(temp2 , dateOfBirth[j]);
							strcpy(dateOfBirth[j] ,dateOfBirth[j+1]);
							strcpy(dateOfBirth[j+1] , temp2);
							
							
						}
					}
				//sort elements
				//print users
				for(i = 0; i< count;i++){
					if(i == 0)
						fprintf(database,"%s %s %s %s %s",Username[i],fname[i],lname[i],dateOfBirth[i],password[i]);
					else
						fprintf(database,"\n%s %s %s %s %s",Username[i],fname[i],lname[i],dateOfBirth[i],password[i]);
				}
				fclose(database);
				break;
		
		
		}
	   
    }while(choice != 3);
    //fclose(inp);
    //fclose(out);
    
    return 0;
}
void menu1(){
	printf("\n**********************************");
	printf("\n|       Menu 1                   |");
	printf("\n**********************************");
	printf("\n    1 - Log in ");
	printf("\n    2 - Sign in");
	printf("\n    3 - Exit Program");
	printf("\n**********************************");


}
void menu2(){
	printf("\n**********************************");
	printf("\n|       Menu 2                   |");
	printf("\n**********************************");
	printf("\n    1 - Change username ");
	printf("\n    2 - Change password");
	printf("\n    3 - Logout ");
	printf("\n**********************************");
	

}
//Function used in the comparison of the qsort
int cmpfunc (const void * a, const void * b)
{
   return ( *(char*)a > *(char*)b );
}

int contains(char a[]){
	int i,MaxComSubSequence;
	char temp[100];
	qsort(a, strlen(a), sizeof(char), cmpfunc);
	for(i = 0; i<count;i++)
			if(strlen(a) == strlen(Username[i])){
				strcpy(temp,Username[i]);
				//sorting the characters of the username
				qsort(temp, strlen(temp), sizeof(char), cmpfunc);
				//computing the longest common subsequence
				MaxComSubSequence = LCS( a, temp, strlen(a), strlen(Username[i]));
				//checking at least 80% ùatch
				if(MaxComSubSequence >= ceil(0.8*strlen(a)))
					return i;
			}
	return -1;
				
}

/* Returns length of LCS for X[0..m-1], Y[0..n-1] */
int LCS( char *X, char *Y, int m, int n )
{
   if (m == 0 || n == 0)
     return 0;
   if (X[m-1] == Y[n-1])
     return 1 + LCS(X, Y, m-1, n-1);
   else
     return maxi(LCS(X, Y, m, n-1), LCS(X, Y, m-1, n));
}
 
/* Utility function to get max of 2 integers */
int maxi(int a, int b)
{
    return (a > b)? a : b;
}


int validPass(char a[]){
	int k, n= strlen(a),upperAlpha=0, lowerAlpha=0,digit=0,otherCharacter=0;
	if(n != 12)
		return 0;
	else{
		for(k = 0; k<n ;k++){
			if(isalpha(a[k])){
				if(isupper(a[k]))
					upperAlpha++;
				else
					lowerAlpha++;
			}else if(isdigit(a[k]))
				digit++;
			else if(a[k] != '@' && a[k] != '\\' && a[k] != ';')
				otherCharacter++;
		}
		if(upperAlpha !=3 || lowerAlpha != 3 || digit !=3 || otherCharacter !=3)
			return 0;
		return 1;
	
	}
}
int checkPass(char a[],int b){
	int i;
	char temp[50],ctemp;
	if(strcmp(a,password[b]) == 0)
		return 1;
	return 0;
}

void encrypte(char a[]){
	int k,n;
	n = strlen(a);
	for(k = 0; k<n ;k++){
		a[k] += 15;
		
	}
}

void decrypte(char a[]){
	int k,n;
	n = strlen(a);
	for(k = 0; k<n ;k++){
		a[k] -= 15;
		
	}
}

int computeAge(char a[]){
	int day,month,year;
	if(strlen(a) == 9){
		day = ((a[0]-'0')*10)+(a[1]-'0');
		year = ((a[5]-'0')*1000)+((a[6]-'0')*100)+((a[7]-'0')*10)+(a[8]-'0');
		if(a[2] == 'd' || a[2] == 'D')
			month = 12;
		else if(a[2] == 'N' || a[2] == 'N')
			month = 11;
		else if(a[2] == 'O' || a[2] == 'O')
			month = 10;
		else if(a[2] == 'S' || a[2] == 's')
			month = 9;
		else if(a[2] == 'F' || a[2] == 'f')
			month = 2;
		else if(a[2] == 'j' && a[3] == 'a')
			month = 1;
		else if(a[2] == 'j' && a[3] == 'u' && a[4] == 'n')
			month = 6;
		else if(a[2] == 'j' && a[4] == 'l')
			month = 7;
		else if(a[2] == 'm' && a[4] == 'r')
			month = 3;
		else if(a[2] == 'm' && a[4] == 'y')
			month = 5;
		else if(a[2] == 'a' && a[3] == 'p')
			month = 4;
		else
			month = 8;
	}else{
		day = a[0]-'0';
		year = ((a[4]-'0')*1000)+((a[5]-'0')*100)+((a[6]-'0')*10)+(a[7]-'0');
		if(a[1] == 'd' || a[1] == 'D')
			month = 12;
		else if(a[1] == 'N' || a[1] == 'N')
			month = 11;
		else if(a[1] == 'O' || a[1] == 'O')
			month = 10;
		else if(a[1] == 'S' || a[1] == 's')
			month = 9;
		else if(a[1] == 'F' || a[1] == 'f')
			month = 2;
		else if(a[1] == 'j' && a[2] == 'a')
			month = 1;
		else if(a[1] == 'j' && a[2] == 'u' && a[3] == 'n')
			month = 6;
		else if(a[1] == 'j' && a[3] == 'l')
			month = 7;
		else if(a[1] == 'm' && a[3] == 'r')
			month = 3;
		else if(a[1] == 'm' && a[3] == 'y')
			month = 5;
		else if(a[1] == 'a' && a[2] == 'p')
			month = 4;
		else
			month = 8;
	}

	if(day<1 && month<12 && year == 2015) 
		return 0;
	else if((day==1 && month==12 && year < 2015) || (day<1 && month<12 && year < 2014))
		return 2015-year;
	else if (day>1 && month==12 && year < 2015)
		return 2015 - year - 1;
	else
		return 2015-year;
}
void swap(char *str1, char *str2){
  char *temp = str1;
  str1 = str2;
  str2 = temp;
}

void swapAge(int *str1, int *str2){
  int *temp = str1;
  str1 = str2;
  str2 = temp;
}
