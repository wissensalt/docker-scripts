package com.wissensalt.rnd.dockercopycommand;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@SpringBootApplication
public class DockerCopyCommandApplication {

	public static void main(String[] args) {
		SpringApplication.run(DockerCopyCommandApplication.class, args);
	}

	@GetMapping("/")
	public String index() {
		return "Docker Copy Command Application is Running";
	}
}
