package ru.neoflex.app.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.Authentication;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.*;
import ru.neoflex.app.domain.User;
import ru.neoflex.app.repository.UserRepository;
import ru.neoflex.app.service.UserService;

import java.security.Principal;
import java.util.Random;

@RestController
@RequestMapping(path = "account")
public class AccountController {
    Random random = new Random(System.currentTimeMillis());

    @Autowired
    private UserService userService;

    @Autowired
    private UserRepository userRepository;//for test

    @GetMapping("/hello")
    public String hello(HttpServletRequest httpServletRequest, ModelMap model) {
        model.addAttribute("user_model", "test");
        return "hello";
    }

    @PostMapping("/registration")
    public User addUser(@RequestBody User user) {
        String login = (user.getMail() + random.nextInt()).replaceAll("@|\\.", "");

        user.setAmount(0);
        user.setCurrency("RUB");
        user.setLogin(login);

        if (!userService.saveUser(user)){
            throw new IllegalStateException("Can't not save user");
        }

        return userService.findUserByLogin(login);
    }

    @GetMapping("info")
    public @ResponseBody User userInfo(@AuthenticationPrincipal User user) {
        return user;
    }

    @GetMapping("version")
    public @ResponseBody String version(Authentication authentication) {
        return "1.4";
    }

    @GetMapping("/del")//for test
    public @ResponseBody String deleteAll() {
        var users = userRepository.findAll();

        users.stream().forEach(u -> userRepository.delete(u));
        return "Good";
    }
}
