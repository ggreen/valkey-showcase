package valkey.sql.source;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ValkeySqlCdcSourceApp {

	public static void main(String[] args) {

		System.out.println("*****ENV:"+ System.getenv());

		SpringApplication.run(ValkeySqlCdcSourceApp.class, args);
	}

}
