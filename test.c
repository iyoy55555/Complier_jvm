int x=20;
float f = 3.5;

float foo (int a,int b){
	float r = a+b;
	return r;
}

void pp (){
	print("call pp");
}

void main(){
	//string s = "Hello";
	float d = 10.0;
	int i =9;
	//float z = d/0;
	f += 1+2.1;
	f--;
	while(i<=15){
		i++;
		print(i);
	}
	print(f);
	if(f > d){
		print("f>d");
	}else if(x == 20){
		if(x>15){
			print("x>15");
		}else{
			print("x<15");
		}
	}else {
		print(x);
	}
	//float g= f%1.2;
	pp();
	//int QQ = foo(x,d) + 3;
	//print(k);
}
