package ru.neoflex.app.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import ru.neoflex.app.domain.HistoryActiveUserSimple;
import ru.neoflex.app.domain.User;
import ru.neoflex.app.repository.HistoryActiveUserRepository;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping(path = "session")
public class SessionController {

    @Autowired
    private HistoryActiveUserRepository historyActiveUserRepository;

    @GetMapping
    public List<HistoryActiveUserSimple> get(HttpServletRequest request, @AuthenticationPrincipal User user) {
        request.getSession().setAttribute("user_agent", request.getHeader("user-agent"));

         return historyActiveUserRepository.getAll().stream()
                 .filter(u -> u.getUserId() != null && u.getUserId().equals(user.getId()))
                 .sorted((o1, o2) -> Long.compare(o2.getLastActive(), o1.getLastActive()))
                 .collect(Collectors.toList());
    }
}
