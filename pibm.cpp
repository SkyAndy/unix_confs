#include <iostream>
/*
File pibm.cpp
g++ pibm.cpp -o pibm
*/

using namespace std;

int main()
{
    unsigned int genau;
    long double pi=1.0;
    unsigned int n;

    cout << "Wie genau soll Pi berechnet werden? ";
    cin >> genau;

    for(n=3; n<=genau; n+=2)
    {
        if(n%4==1) pi+=1.0/n;
        else pi-=1.0/n;
    }
    pi*=4;
    cout.precision(17);
    cout << pi;
    return 0;
}
