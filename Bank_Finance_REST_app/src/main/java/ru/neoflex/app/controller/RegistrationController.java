package ru.neoflex.app.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import ru.neoflex.app.domain.User;
import ru.neoflex.app.repository.UserRepository;
import ru.neoflex.app.service.UserService;

import java.util.Collections;
import java.util.Map;

@Controller
public class RegistrationController {
    @Autowired
    private UserService userService;

    @GetMapping("/registration")
    public String registration() {
        return "registration";
    }

//    @PostMapping("/registration")
//    public String addUser(User user, Map<String, Object> model) {
//        boolean userRes = userService.saveUser(user);
//        System.out.println(userRes);
//        System.out.println("Add user");
//        return "redirect:/login";
//    }
}