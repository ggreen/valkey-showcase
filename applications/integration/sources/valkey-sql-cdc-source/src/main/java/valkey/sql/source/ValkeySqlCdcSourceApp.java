package valkey.sql.source;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ValkeySqlCdcSourceApp {

	public static void main(String[] args) {
		SpringApplication.run(ValkeySqlCdcSourceApp.class, args);
	}

}
