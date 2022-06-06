package ru.neoflex.app.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.Authentication;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.*;
import ru.neoflex.app.domain.User;
import ru.neoflex.app.service.UserService;

@RestController
@RequestMapping(path = "account")
public class AccountController {

    @Autowired
    private UserService userService;

    @GetMapping("/hello")
    public String hello(HttpServletRequest httpServletRequest, ModelMap model) {
        model.addAttribute("user_model", "test");
        return "hello";
    }

    @PostMapping("/registration")
    public User addUser(User user) {

        if (!userService.saveUser(user)){
            throw new IllegalStateException("Can't not save user");
        }

        return user;
    }

    @GetMapping("version")
    public @ResponseBody String version(Authentication authentication) {
        System.out.println(authentication.getName());
        return "1.1";
    }
}
