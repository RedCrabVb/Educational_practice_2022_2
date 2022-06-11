package ru.neoflex.app.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import ru.neoflex.app.domain.HistoryActiveUser;
import ru.neoflex.app.domain.User;
import ru.neoflex.app.repository.HistoryActiveUserRepository;

import java.text.SimpleDateFormat;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping(path = "session")
public class SessionController {

    @Autowired
    private HistoryActiveUserRepository sessionRepository;

    @GetMapping
    public Map<String, Set<HistoryActiveUser>> get(HttpServletRequest request, @AuthenticationPrincipal User user) {
        SimpleDateFormat sdf = new SimpleDateFormat("MMM-dd-yyyy");

         return sessionRepository.findAll().stream()
                //.filter(u -> u.getUserId() != null && u.getUserId().equals(user.getId()))
                .collect(Collectors.groupingBy((h) -> sdf.format(new Date(h.getLastActive())).toString(), Collectors.toSet()));
    }
}
