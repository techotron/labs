// https://www.youtube.com/watch?v=Osm5SCw6gPU&list=PLzUGFf4GhXBL4GHXVcMMvzgtO8-WEJIoY

package main

import (
	"encoding/json"
	"fmt"
)

type Book struct {
	Title string 	`json:"title"`
	Author Author `json:"author"`
}

type Author struct {
	Name string 		`json:"name"`
	Age int 				`json:"age"`
	Developer bool 	`json:"is_developer"`
}

type SensorReading struct {
	Name string `json:"name"`
	Capacity int `json:"capacity"`
	Time string `json:"time"`
	Information Info `json:"info"`
}

type Info struct {
	Description string `json:"desc"`
}

func main() {
	// Converting TO json output
	fmt.Println("Hello World")

	author := Author{Name: "Elliot Forbes", Age: 25, Developer: true}

	book := Book{Title: "Learning concurrency in Python", Author: author}

	fmt.Printf("%+v\n", book)

	byteArray, err := json.Marshal(book)
	if err != nil {
		fmt.Println(err)
	}

	byteArrayIndent, err := json.MarshalIndent(book, "", "  ")
	if err != nil {
		fmt.Println(err)
	}

	fmt.Println(string(byteArray))
	fmt.Println(string(byteArrayIndent))

	// Converting FROM json input (when you know the structure of the JSON)
	jsonString := `{"name": "battery sensor", "capacity": 40, "time": "2020-08-01T00:06:23Z", "info": {"desc": "a sensor reading"}}`

	var reading SensorReading
	unmarshalErr := json.Unmarshal([]byte(jsonString), &reading)
	if unmarshalErr != nil {
		fmt.Println(err)
	}

	fmt.Printf("%+v\n", reading)


// Converting FROM json input (when you DON'T know the structure of the JSON)

var unknownJsonStucture map[string]interface{}
unknownJsonStuctureErr := json.Unmarshal([]byte(jsonString), &unknownJsonStucture)
if unknownJsonStuctureErr != nil {
	fmt.Println(err)
}

fmt.Printf("%+v\n", unknownJsonStucture)


}

