// ID :71750_72494
#include<stdio.h>//Standard input output library with standard functions such as scanf and printf
#include <string.h> //Library that has the functions dedicated to handling strings
#include <ctype.h> //Library that has functions that check the type of charcaters (digits, uppercase..) or chnages them to another type

int menu (void); //Asks the user if they want to login, signin or exit
void login (void); //Allows the user to login, then to chnage their password or username
void signin(void); //create a new user
void exitfun(void); //Exit the program
int countage (char dob[]); //To count the age of the users
double compare(char arr1[], char arr2[], int line); //Find the percentage of similarity between two strings
void encrypt(char arr[], int size); //Encrypt a string by finding its Ceaser cipher
void decrypt(char arr[], int size); //Decrypt a string
void sortbyage (void); //Sorts the users by their age
void swap(char arr1[], char arr2[]); //Swaps to strings

/*Declaring global variables since we're using the same input parameters in most of the functions*/
char usernames[50][15], fnames[50][10], lnames[50][10], dobs[50][12], passwords[50][13]; 
int nusers=4, ages[20];

int main(){
	
	int answer, i;
	
	FILE *database; //Declaring the file we are using as an input file
	database=fopen("database.txt","r"); //Opening the file to read from it
	
	for(i=0; i<4; i++){ 
		fscanf(database, "%s", usernames[i]); //Transfering the first string of each line into an array
		fscanf(database, "%s", fnames[i]); //Transfering the second string of each line into an array
		fscanf(database, "%s", lnames[i]); //Transfering the third string of each line into an array
		fscanf(database, "%s", dobs[i]); //Transfering the fourth string of each line into an array
		fscanf(database, "%s", passwords[i]); //Transfering the fifth string of each line into an array
		encrypt(passwords[i], 12);//We must encrypt the password for the sake of safety.
	}
	
	answer=menu(); //Calling the menu so the user chooses whether to login, signin or exit
	
	while (answer!=0){
		if (answer==1)//Once the user presses 1, he's calling the function login.
			login();	
		else 
			signin();//The user has chosen 2 he then procedes to sign it.
			
		answer=menu();//The answer here is either 1 2 or 0 in order to determine the user's choice.
	}
	
	exitfun(); //Once the choice is 0 the function exit is called to exit the program
	
	return 0;
}

//The function Menu displays the choices the user has which are either logingin by returning 1, signingin which returns 2, or exiting by pressing on 0.
int menu (void){
	int answer;
	printf("\n\2\3\2\3\2 Welcome to your Program \2\3\2\3\2\n\nPress 1 to log in\nPress 2 to sign in \nPress 0 to exit\n ");
	scanf("%d", &answer);
	return answer;
}

/*The login function checks if the username and the password entered by the user match the information in the database (minimum of 80% for the username). 
If a match is found, the user chooses to either change his username or password or log out and go back to the login page
If the program finds no match, the user is asked again to re enter both username and paswword to go another time through the same login process*/
void login (void){
	
	char username[15], password[13];
	double occurence;
	int i, j, flagun=0, flagpw=0, choice, countup=0, countlow=0, countdigit=0, countspe=0, flag1=0, flag2=0, age, flag=0;
	
	do{
		do{
			printf("\n\2\3\2\3\2 Log in \2\3\2\3\2\n");
			printf("\n");
			printf("Please enter your unsername > "); 
			scanf("%s", username);
			for(i=0; i<nusers; i++){
				occurence=compare(username, usernames[i], i);//the occurence will give us the percentage of the similarity between the username entered by the user and the usernames inside the database
				if (occurence>=80){
					flagun=1;
					break;
				}	
			}
			printf("Please enter your password > ");
			scanf("%s", password);
			password[12]='\0';
			decrypt(passwords[i], 12);//The password from the database corresponding to the matching user must be decrypted in order to compare it with the username entered by the user.
			if (strcmp(password, passwords[i])==0){//The password must 100% match that is why we don't send it to the function compare.
				flagpw=1;
			}
			encrypt(passwords[i], 12);//Once the comparison done, the password must be re-encrypted.
		}while(flagun==0 || flagpw==0);
		
		printf("\nWelcome, you have successfully logged in.\n");
		
		//Once logged in, the user has acces to all his information including their age which the program computed using the function age
		age=countage(dobs[i]);
		
		printf("\nFirst name: %s\n", fnames[i]);
		printf("Last name: %s\n", lnames[i]);
		printf("Age: %d\n", age);
		
		//Here is where the user is asked to either change his username or password or exit and then return to the login page.
		
		printf("\nPress 1 if you want to change your username\nPress 2 if you want to change your password\nPress 3 if you want to log out\n ");
		scanf("%d", &choice);
		
		switch(choice){
			case 1://this choise allows the user to change their username.
				do{
					flag2=0;
					printf("\nPlease enter username > ");
					scanf("%s", username);
					for(j=0; j<nusers; j++)
						occurence=compare(username, usernames[j], i);//The program compares between the new username and the ones in the database.
						if(occurence>=80){
							printf("User already exists.");//if there's a match starting from 80% the user is asked to enter another one.
							flag2=1;
							break;
						}
				}while(flag2==1);
				if(flag2==0){
					strcpy(usernames[i],username);
					printf("Your username has been successfully changed.\n");//This means that no match was found and that the user has been able to change his username.
				}
				break;
		
			case 2://this choise allows the user to change their password.
				do{//we initialize the counts of digits, lower case and upper case letters in addition to special characters for we need exactly 3 of each for the password to be valid
					countup=0;
				 	countlow=0; 
				 	countdigit=0; 
				 	countspe=0; 
				 	flag=0;
					printf("Please enter a password of 12 characters which contains 3 lower case letters, 3 upper case letters, 3 digits and 3 special characters different from '@', '\' and ';' > ");
					scanf("%s", password);
					for(j=0; j<12; j++){
						if(isupper(password[j])) //Checking if the password contains three upper case letters
							countup++;
						else if(islower(password[j]))//Checking if the password contains three lower case letters
							countlow++;
						else if(isdigit(password[j]))//Checking if the password contains three digits
							countdigit++;
						else countspe++;//Checking if the password contains three special characters
						if (password[j]=='@' || password[j]==';' || password[j]=='\\' )//The password must not contain @, ; or \ or it is invalid.
							flag=1;
					}
				}while(countup!=3 || countlow!=3 || countdigit!=3 || countspe!=3 || flag==1); /*While the above conditions are not fulfilled
																				the program must keep on asking the user to re-enter a valid password*/
				encrypt(password, 12); //Now that the user has successfully changed his password, the program must encrypt it.
				
				strcpy(passwords[i],password); //Overwriting the old username by the new one
				printf("Password successfully changed");
				break;
			}
	}while(choice==3);//This choice takes the user back to the login page.
}

/*The signin function allows the user to create a new account. The user will then be asked to enter a new username that doesn't reach 80% in similarity or the user will be asked to enter a new username.
Once the username valid, the user must enter a 12 characters password that contains 3 digits, 3 lower case letters, 3 upper case and 3 special characters different from @, ; and \
The user is also asked to enter his first and last name and his date of birth in the following format ddmmmyyyy*/
void signin (void){
	
	char username[15], password[13]; 
	int countup=0, countlow=0, countdigit=0, countspe=0, flag=0, i, j;
	double occurence;
	
	printf("\n");
	printf("\2\3\2\3\2 Sign in \2\3\2\3\2\n");
	printf("\n");
	
	printf("Please enter username > ");
	scanf("%s", username);
	
	for(i=0; i<nusers; i++){ //If the new username has at least 80% similarity with any of the other existing usernames, the user is asked to enter a new one
		occurence=compare(username, usernames[i], i);
		while(occurence>=80){
		printf("User already exists. Please enter a new username > ");
		scanf("%s", username);
		occurence=compare(username, usernames[i], i);
		}
	}
	strcpy(usernames[nusers],username);//This will allow the program to save the new username
	
	printf("Please enter first name > ");
	scanf("%s", fnames[nusers]);
	printf("Please enter last name > ");
	scanf("%s", lnames[nusers]);
	printf("Please enter date of birth in the following format XXjanXXXX > ");
	scanf("%s", dobs[nusers]);
	
	do{
		countup=0;
 		countlow=0; 
 		countdigit=0; 
	 	countspe=0; 
	 	flag=0;
		printf("Please enter a password of 12 characters which contains 3 lower case letters, 3 upper case letters, 3 digits and 3 special characters different from '@', '\\' and ';' > ");
		scanf("%s", password);
		
		for(j=0; j<12; j++){
			if(isupper(password[j]))
				countup++;
			else if(islower(password[j]))
				countlow++;
			else if(isdigit(password[j]))
				countdigit++;
			else countspe++;
			if (password[j]=='@' || password[j]==';' || password[j]=='\\' )
				flag=1;
		}
	}while(countup!=3 || countlow!=3 || countdigit!=3 || countspe!=3 || flag==1);
	
	printf("\nThe new user has been created.\n\nUsername: %s\nPassword: %s\n", username, password);
	
	encrypt(password, 12);//The password must get encrypted to avoid any security breach.
	strcpy(passwords[nusers],password);//This will allow the program to save the new password.
	nusers++;
}

/*The exit function will save every change and addes account to an output file.
The users information will be displayed in the output file sorted by age from the oldest to the youngest.
The passwords are also encrypted.*/
void exitfun(void){
	int i;
	FILE *output;
	printf("Thank you for using our program.\n\n");
	output=fopen("output.txt","w");//We open the output file where the information will be directly written.
	sortbyage();//We call the function to sort by age.
	for(i=0; i<nusers; i++){
		fprintf(output,"%s %s %s %s %s\n", usernames[i], fnames[i], lnames[i], dobs[i], passwords[i]);//All the sorted information gets printed in the output file.
	}
	fclose(output);//Now that we're done, the file gets closed.
}

//This function has been used several times to find the percentage of similarity between the new/entered usernames and the ones already in the databse.
double compare(char arr1[], char arr2[], int line){
	int i, j,len1, len2;
	double occurence, count=0;
	len1=strlen(arr1);
	len2=strlen(arr2);
	
	if (len1!=len2)//The two passwords must be of the same length to start comparing them.
		return 0;
	else {	
		for(i=0; i<len1; i++){
			for(j=0; j<len2; j++){
				if (arr1[i]==arr2[j]){//Here we compare character by character and each time a match is found, the count increases by 1.
					count++;
					j=0;//j must be re-initialized so that each character from the first word will be compared to the second word starting from the first letter.
					i++;
				}
			}
		}
	}
	
	occurence=(count/len1)*100.0;
	return occurence;//This function returns the occurence as a double based on the length of the word.
}

/*The function count age computes the age of the user who's successfully logged in*/
int countage (char dob[]){
	char temp1[10], temp2[3];
	int arr[5], year, age, compare, len;
	
	len=strlen(dob);//We must find the length for the year is the last four digits of the age string.
	
	strcpy(temp1, &dob[len-4]);
	sscanf(temp1, "%d", &year);//sscanf will turn the year from a string to an integer.
	strncpy(temp2, &dob[len-7], 3);//We need the month to determine if the user is one year younger if his month of birth comes before december.
	
	temp2[3]='\0';
	age = 2015 - year;
	compare=strcmp(temp2, "dec");
	
	if(compare==0)
		age--;
		
	return age;
}

//Encrypting solves many security issues. In our program, it adds 15 to the ASCII of each letter the user enters and gives us the character that matches to that new ASCII.
void encrypt(char arr[], int size){
	int i;
	
	for(i=0; i<size; i++)
		arr[i]=arr[i]+15;
}

//Decyrpting deducts 15 from the ASCII of each character and finds the matching character.
void decrypt(char arr[], int size){
	int i;
	
	for(i=0; i<size; i++)
		arr[i]=arr[i]-15;
}

/*This is the function called in the exit that'll sort ever single user information and any change occured 
			based on their year of birth from the oldest to the youngest*/
void sortbyage (void){
	int i, j;
	
	for (i=0; i<nusers; i++){ 
		for (j=0; j<nusers-1-i; j++){
			if(countage(dobs[j])<countage(dobs[j+1])){
				swap(usernames[j], usernames[j+1]);
				swap(fnames[j], fnames[j+1]);
				swap(lnames[j], lnames[j+1]);
				swap(dobs[j], dobs[j+1]);
				swap(passwords[j], passwords[j+1]);
			}
		}
	}
}


void swap(char arr1[], char arr2[]){
	char temp[20];
	
	strcpy(temp,arr1);
	strcpy(arr1,arr2);
	strcpy(arr2,temp);
}
