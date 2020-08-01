package main

import (
	"fmt"
)

func main() {
	myInt := 15
	pointerAddress := &myInt // Memory address of pointer (in hex)
	pointerValue := *pointerAddress // Value of pointer (15)
	fmt.Println(myInt) // 15
	fmt.Println(pointerAddress) // (Hex memory address)
	fmt.Println(pointerValue) // 15

	*pointerAddress = 5 // Setting the value of the pointer to 5

	fmt.Println(myInt) // 5
	fmt.Println(*pointerAddress) // 5
}

// Variable creates a space in memory. This has an address and a value.
// &variableName == memory address of the variable
// *pointerAddress == read value of the variable
