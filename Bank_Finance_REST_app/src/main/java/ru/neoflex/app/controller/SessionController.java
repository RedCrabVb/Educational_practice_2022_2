package ru.neoflex.app.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.neoflex.app.domain.HistoryActiveUser;
import ru.neoflex.app.domain.User;
import ru.neoflex.app.repository.HistoryActiveUserRepository;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping(path = "session")
public class SessionController {

    @Autowired
    private HistoryActiveUserRepository sessionRepository;

    @GetMapping
    public List<HistoryActiveUser> get(@AuthenticationPrincipal User user) {
        return sessionRepository.findAll().stream().filter(s -> s.getUseSessionId() == user.getId()).collect(Collectors.toList());
    }
}
