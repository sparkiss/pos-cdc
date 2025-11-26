package main

import (
	"fmt"
	"github.com/IBM/sarama"
	"log"
)

func main() {
	fmt.Println("CDC Consumer starting...")

	//FIXME: hardcoded values -- extract it in config
	//TAG: environment varialbe
	brokers := []string{"localhost:9092"}

	// Create Kafka admin client to list topics
	config := sarama.NewConfig()
	config.Version = sarama.V2_8_0_0

	//TODO: Add proper error handling
	//For now, it just crashes if something goes wrong
	admin, err := sarama.NewClusterAdmin(brokers, config)
	if err != nil {
		log.Fatalf("Failed ro create admin: %v", err)
	}
	defer admin.Close()

	topics, err := admin.ListTopics()
	if err != nil {
		log.Fatalf("Failed to list topics: %v", err)
	}

	fmt.Printf("\nfound %d topics:\n", len(topics))
	for name := range topics {
		fmt.Printf("  - %s\n", name)
	}

	fmt.Println("\nCDC Consumer finished.")
}
