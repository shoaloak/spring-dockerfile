package com.axelkoolhaas.springdockerfile;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class SpringdockerfileApplication {

	@RequestMapping("/")
	public String home() {
		return "Hello there!";
	}

	public static void main(String[] args) {
		SpringApplication.run(SpringdockerfileApplication.class, args);
	}

}
