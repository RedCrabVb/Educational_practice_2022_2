package ru.neoflex.app.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.repository.query.Param;
import org.springframework.web.bind.annotation.*;
import ru.neoflex.app.domain.AccountTransactions;
import ru.neoflex.app.domain.TypeTransactions;
import ru.neoflex.app.repository.AccountTransactionsRepository;
import ru.neoflex.app.repository.TypeTransactionsRepository;
import ru.neoflex.app.repository.UserRepository;
import ru.neoflex.app.service.UserService;

import java.security.Principal;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping(path = "transactions")
public class AccountTransactionsController {

    @Autowired
    private AccountTransactionsRepository accountTransactionsRepository;

    @Autowired
    private TypeTransactionsRepository typeTransactionsRepository;

    @Autowired
    private UserRepository userRepository;

    @PutMapping
    public AccountTransactions add(@RequestBody AccountTransactions accountTransactions, Principal principal) {
        if (accountTransactions.getAmount() < 0) {
            throw new IllegalStateException("Not valid amount");
        }
        var currentDate = new Date(System.currentTimeMillis());

        var user = userRepository.findByLogin(principal.getName());
        accountTransactions.setTUser(user);
        accountTransactions.setTypeTransactions(typeTransactionsRepository.findById(1L).get());
        accountTransactions.setDate(currentDate);


        return accountTransactionsRepository.save(accountTransactions);
    }

    @GetMapping(path = "type")
    public List<TypeTransactions> get() {
        return typeTransactionsRepository.findAll();
    }

    @GetMapping
    public List<AccountTransactions> find(Principal principal) {
        var idUser = userRepository.findByLogin(principal.getName()).getId();
        return accountTransactionsRepository.findAll().stream().filter(a -> a.getTUser() != null && a.getTUser().getId().equals(idUser)).collect(Collectors.toList());
    }

}
