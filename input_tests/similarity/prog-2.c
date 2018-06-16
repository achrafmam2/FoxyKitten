#include <stdio.h>
#include <string.h>
#include <ctype.h>

int menu();//asks the user for the action he wants to perform, either log in, sign in, or exit
void logIn(char pass[][50],char uname[][50],char fname[][50],char lname[][50],char birthday[][10], int size);//checks whether the user name and password entered by the user meet each one of them's requirements
int signIn(char pass[][50],char uname[][50],char fname[][50],char lname[][50],char birthday[][10], int size);//allows the user to create an account following some requirements
void exit(char pass[][50], char uname[][50], char fname[][50], char lname[][50], char birthday[][10], int size);// takes all the database information and adds the modifications and stores them in an output file
int compareUsername(char arr1[], char arr2[][50], int *u, int size); //checks whether the user name condition is satisfied or not
int countAge(char birthday[]); //computes the user's age
void encryptPass(char password[], int length);//adds 15 to each character of the password to encrypt it
void decryptPass(char password[], int length);//subtracts 15 from each character of the password to decrypt it
void sortByAge(char birthday[][10], char pass[][50], char uname[][50], char fname[][50], char lname[][50], int size);//takes data from the exit function, sorts it by age, then returns it to the exit function to be stored in the output file
void swapString(char a[], char b[]);// swaps strings
void swapArrays(int *a, int *b);// swaps arrays

int main(void) {
	//the user's input will be stored in a one dimensional array, while the database informations must be stored in 2 dimensional arrays
	char pass[50][50], uname[50][50], fname[50][50], lname[50][50], birthday[10][10];
	int answer, i, len, size = 4;
	FILE *inp;

	//We must get access to the database file and read its elements to be able to implement our function

	inp = fopen("database.txt", "r");

	//if the file doesn't exist, the program must shut down

	if(inp == NULL)
		return 0;
	//after getting access to the file, we must create a loop that copies each group of strings line by line from the database to a seperate array

	for(i = 0; i < 4; i++){
		fscanf(inp, "%s %s %s %s %s", uname[i], fname[i], lname[i], birthday[i], pass[i]);
	}

	//each password after being scanned from the database must be encrypted by sending it to the function encrypt
	for(i = 0; i < 4; i++){
		len = strlen(pass[i]);
		encryptPass(pass[i], len);
	}

    do{
		// we must then call a menu function that will ask the user for the action he wants to perform
		answer = menu();
		// if the user presses 1, we should call the function logIn
		if(answer == 1) logIn(pass, uname, fname, lname, birthday, size);
		// if the user presses 2, we should call the function signIn
		// sign in is the only function of type int, since it is the only function that has the ability of adding data to the arrays, and we must at each time return the new size of the array
		else if(answer == 2) size = signIn(pass, uname, fname, lname, birthday, size);
		/*If the user presses 3, that means the user wants to exit the program
		we must then call the function exit right after thanking the professor for his efforts anf this amazing semester*/
		//PS: smile before starting the correction O:)
		else{

            printf(" Thank you for using this program, the system will now exit... \n");
			exit(pass, uname, fname, lname, birthday, size);
            return 0;
		}
	} while(answer != 3);

	return 0;
}

int menu(){
	int answer;

	//The menu function asks the user for the number corresponding to the action he wants to perform
	printf("Please select the action you want to perform:\n1- Log in\n2- Sign in\n3- Exit\n");
	scanf("%d", &answer);

	return answer;
}
void logIn(char pass[][50],char uname[][50],char fname[][50],char lname[][50],char birthday[][10], int size){
	char username[50], password[15];
	int answer, a, i, j, length, len, M, N, age, P, k, c, len2, flag, digit, lower, upper, spchar;

	//we must create a do while loop since we shall get back to the logIn page each time the user enters wrong input

	do{
		printf("******** Log in ********\n");
		printf("Please enter your username >> ");
		scanf("%s", username);

		/*the username entered by the user is sent to a function that checks whether the input matches 80% or more with one of the existing usernames in the database file
		if the condition is not satisfied, the user is automatically taken back to the logIn page by the end of the do while loop*/

		M=compareUsername(username, uname, &k, size);
		printf("Please enter your password >> ");
		scanf("%s", password);

		/*we must check if the password entered by the user matches 100% with one of the existing passwords in the database file
		if the condition is not satisfied, the user is automatically taken back to the logIn page by the end of the do while loop*/
		for(j=0; j<size; j++){
			len=strlen(pass[j]);
			decryptPass(pass[j], len);
			N=strcmp(password, pass[j]);
			encryptPass(pass[j], len);
			if(N==0){
				P = j;
				break;
			}
		}
		//M==1 is returned if the username condition is satisfied, and N==0 is returned if the password condition is satisfied

		if(M==1 && N==0){

			/*K is the pointer to the line in which the username condition has been satisfied
			P is equal to the line number in which the password condition has been satisfied
			we only pursue to the next step if the username and password are located in the same line*/

			if(k==P){

				//the user's birthday is then sent to a function that computes his age and displays it in addition to his/her first and last name

				age=countAge(birthday[k]);
				printf("Welcome:\nFirst name: %s\nLast name: %s\nAge : %d years old\n", fname[P], lname[P], age);

				//then, the user has to choose wheter he wants to change one of his/her username or password, or logout

				printf("Now:\nPress 1 if you want to change your username\nPress 2 if you want to change your password\nPress 3 to logout\n");
				scanf("%d", &answer);
				if(answer==1){

					//we must use a do while loop that should stop only if the new username condition is not satisfied

						do{
						printf("Please enter a new username >> ");
						scanf("%s", username);

						//the username must be updated, so this time, the new username must match strictly less than 80%

						M=compareUsername(username, uname, &k, size);
						if(M==0){
							//if the condition is satisfied, the username must be updated by being stored in the array instead of the original username
							printf("Your username has been updated\n");
							strcpy(uname[P], username);
							break;
						}
						else
							printf("This username already exists, try again\n");
						}while(M==1);

						//if the username doesn't match with any database username, the username must be stored and the program must return to the menu by breaking the loop
						if(M==0)
							break;

				}
				else if(answer==2){

					//we must use a do while loop that should stop only if the new password condition is satisfied

					do{
							do{
								// we must reinitialize each variable for every time the user enters an invalid password
								flag=0;
								digit=0;
								lower=0;
								upper=0;
								spchar=0;

								printf("Please enter a new password >> ");
								scanf("%s", password);
								len2=strlen(password);

								// there is a counter for each requirement that we will check in the end of the loop

								for(i=0; i<len2; i++){
									if(isdigit(password[i]))
										digit++;
									else if(islower(password[i]))
										lower++;
									else if(isupper(password[i]))
										upper++;
									else
										spchar++;
								}

								//Not all special characters are accepted, '@', ';', and '\' should not be accepted as an input
								for(i=0; i<len2; i++){
									if(password[i]=='@' || password[i]==';' || password[i]=='\\'){
										flag=1;
										break;
									}
								}
								if(digit!=3 || lower!=3 || upper!=3 || spchar!=3)
									flag=1;
								if(flag==1)
									printf("your password does not meet the requirements\n \t Try Again !\n");
								//we used a flag that returns 1 everytime it finds an error in the user's input
							}while(flag==1);

						//the password must be updated, so the new password must match less than 100%
						// we must decrypt every password from the database for the comparaison
						for(i=0; i<size; i++){
							len=strlen(pass[i]);
							decryptPass(pass[i], len);
							N=strcmp(password, pass[i]);
							encryptPass(pass[i], len);
							if(N==0)
								break;
						}
						if(N!=0){
							/*If the new password condition is satisfiedwe must:
							decrypt the matching password from database
							replace the password from database with the new password entered by the user
							display the old and new passwords to the user*/
							printf("Your password has been updated\n");
							printf("Your old password is: ");
							printf("%s\n", pass[P]);
							encryptPass(password, len2);
							strcpy(pass[P], password);
							printf("Your new password is: ");
							printf("%s\n", password);
							break;
						}
						else
							printf("This password already exists, try again\n");
					}while(N==0);
				}
			}
			else
				printf("The username and password you entered are not compatible\n \tTry Again !\n");
		}
		else
			printf("The username or password you entered does not exist\n \tTry Again !\n");

			//the do while loop only stops if the username and password conditions are satisfied, or if the user doesn't decide to logout

	}while(M!=1 && N!=0 || k!=P || answer==3);
}
int signIn(char pass[][50],char uname[][50],char fname[][50],char lname[][50],char birthday[][10], int size){
	char username[50], firstname[50], lastname[50], bday[50], password[50];
	int digit=0, lower=0, upper=0, spchar=0, M=0, i, passlen, flag;

	printf("******* Sign in *******\n");

	//if the user chooses to sign in, he must be asked to enter his first name, last name, and birthday before getting into the username and password loops
	printf("Please enter your first name >> ");
	scanf("%s", firstname);
	printf("Please enter your last name >> ");
	scanf("%s", lastname);
	printf("Please enter your day of birth as a string of format: ddmmmyyyy >> ");
	scanf("%s", bday);

	do{
		printf("Please enter your username >> ");
		scanf("%s", username);
		//we send the username to a funtion that checks whether the user doesn't match 80% with any of the database usernames
		//the 'i' we send to the function is useless, we actually need the third argument in the sign in to point to the line in which the function has found the match
		M=compareUsername(username, uname, &i, size);
		// The function compareUsername returns 1 if it did not find any match, and zero if it found a matching username of more than 80%
		if(M==1)
			printf("The username you entered already exists\n \t Try Again !\n");
	}while(M==1);
	do{
		//every single variable used in this loop must be reinitialized each time the loop condition is not satisfied
		flag=0;
		digit=0;
		lower=0;
		upper=0;
		spchar=0;
		printf("Please enter a password of 12 characters including:\n 3 upper case letters\n 3 lower case letters\n 3 digits \n 3 special characters\n '@' , ';' , '\\' are not accepted\n");
		scanf("%s", password);

		passlen=strlen(password);

		//after getting the user's password, we compute its length and scan each characters using counters to count the number of digits, lowercase letters, uppercase letters, and special characters
		for(i=0; i<passlen; i++){
			if(isdigit(password[i]))
				digit++;
			else if(islower(password[i]))
				lower++;
			else if(isupper(password[i]))
				upper++;
			else
				spchar++;
		}
		// the number of charaacters is not the only requirement, the program must check whether the characters '@', ';', and '\' do not exist in the array
		for(i=0; i<passlen; i++){
			if(password[i]=='@' || password[i]==';' || password[i]=='\\'){
				printf("your password does not meet the requirements\n \t Try Again !\n");
				flag=1;
				break;
			}
		}
		// The password is not accepted if the number of each one of the required type of characters is different than 3
		if(digit!=3 || lower!=3 || upper!=3 || spchar!=3){
			printf("your password does not meet the requirements\n \t Try Again !\n");
			flag=1;
		}
	}while(flag==1);

	//if the password and username conditions are satisfied, the account is then created, and the user's informations must be displayed to him, using an encrypted password
	printf("Congratulations ! Your account has been created.\n");
	printf("Username: %s\n First name: %s\n Last name: %s\n Day of birth: %s\n", username, firstname, lastname, bday);
	printf("Password: ");

	encryptPass(password, passlen);
	printf("%s\n", password);

	// all the new user's data must be stored in the arrays containing the database informations
	strcpy(uname[size], username);
	strcpy(fname[size], firstname);
	strcpy(lname[size], lastname);
	strcpy(birthday[size], bday);
	strcpy(pass[size], password);

	//when the account is created, the array size is bigger, that is why we must add 1 to the array size and return the new size to the main
	size++;

	return size;
}
void exit(char pass[][50],char uname[][50],char fname[][50],char lname[][50],char birthday[][10],int size){
	int i;
	FILE *outp;

	sortByAge(birthday, pass, uname, fname, lname, size);

	outp = fopen("output.txt", "w");
    if(outp == NULL) printf("Error\n");

	for(i = 0; i < size; i++)
		fprintf(outp, "%s %s %s %s %s\n", uname[i], fname[i], lname[i], birthday[i], pass[i]);
}
void sortByAge(char birthday[][10], char pass[][50],char uname[][50],char fname[][50],char lname[][50], int size){
	int i, j, len, year[50];
	char temp2[10][10], temp1[10][10];

	/*the birthday size is never the same since its format is dmmmyyyy or ddmmmyyyy, but the last four characters always represent the year
	that is why we subsract four from the length after computing it, and take those four last characters, store them in a temporary array, then convert them to integers using the function sscanf, then restore them in another 1 dimentional array*/
	for(i=0; i<size; i++){
		len=strlen(birthday[i]);
		strcpy(temp1[i], &birthday[i][len-4]);
		sscanf(temp1[i], "%d", &year[i]);
	}
	/*if the first year is bigger than the second year, that means that the user born in the first one is younger than the one born in the second one
	using the bubble sort, we can compare all the years stored in the array of birthdays, then swap all the characters in the arrays of the same index as the swapped years*/
	for(i=0; i<size; i++){
		for(j=0; j<size-1-i; j++){
			if(year[j]>year[j+1]){
				swapArrays(&year[j], &year[j+1]);
				swapString(pass[j], pass[j+1]);
				swapString(uname[j], uname[j+1]);
				swapString(fname[j], fname[j+1]);
				swapString(lname[j], lname[j+1]);
				swapString(birthday[j], birthday[j+1]);
			}
		}
	}
}
void swapString(char a[], char b[]){
	char temp[100];

	//This type of swapping is used when dealing with arrays
	strcpy(temp, a);
	strcpy(a, b);
	strcpy(b, temp);

}
void swapArrays(int *a, int *b){
	int temp;

	//This type of swapping is used when dealing with characters
	temp=*a;
	*a=*b;
	*b=temp;
}
int compareUsername(char arr1[], char arr2[][50], int *u, int size){
	double percentage, len1, len2, count;
	int i, j, k, answer=0;

	/*i is a counter for lines
	j is a counter for the input characters
	k is a counter for the database usernames' characters*/

	len1=strlen(arr1);
	for(i=0; i<size; i++){

		//the count of similar characters between the database userame and the user's input is reinitialized to '0' in each line

		count=0;

		//if the user's input is not the same size as the database's username length, the program must print an error despite the fact that they match more than 80%

		len2=strlen(arr2[i]);
		if(len1!=len2){
			answer=0;
		}
		else{
			for(j=0; j<len1; j++){
				for(k=0; k<len2; k++){
					if(arr1[j]==arr2[i][k]){
						count++;
						j++;
						k=0;

						//each time the program finds a character similarity, it must move to the next input character and reinitialize the database username's counter at line 'i'

					}
				}
			}
			percentage=count/len1;

			//if the input matches more than 80% with the database username at line 'i', the loop must break and return 1 and 'i' to the main

			if(percentage>=0.8){
				answer=1;
				break;
			}
		}
	}
	//we're using a pointer to the line in which the username condition is satisfied to check whether the username and password entered are in the same line or not
	*u=i;
	return answer;
}
int countAge(char birthday[]){
	char temp1[10], temp2[3];
	int arr[5], year = 0, age, compare, len;

	/*the birthday is given as a string
	we must take the four last characters of the string that always represent the year of birth, then convert them to integers using a temporary array
	we must subsrtact the integer found from 2015 to find the user's age*/

	len=strlen(birthday);
	strcpy(temp1, &birthday[len-4]);
	sscanf(temp1, "%d", &year);
	strncpy(temp2, &birthday[len-7], 3);
	temp2[3]='\0';
	age = 2015 - year;
	/*We compile the program as of December 1st 2015
	 if the birthday comes in december(since there's no month after december), we must substract 1 from the age assuming that he did not celebrate his birthday yet*/
	compare=strcmp(temp2, "dec");
	if(compare==0)
		age--;
	return age;
}
void encryptPass(char pass[], int length){
	int i;

	//Adding 15 to each character of the array shows the array in its encrypted format
	for(i = 0; i < length; i++)
		pass[i] = pass[i] + 15;
}
void decryptPass(char pass[], int length){
	int i;

	//Substracting 15 from each character of the array shows the array in its decrypted format
	for(i=0; i<length; i++)
		pass[i] = pass[i]-15;
}
