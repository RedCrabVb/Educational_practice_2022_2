package ru.neoflex.app.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.repository.query.Param;
import org.springframework.web.bind.annotation.*;
import ru.neoflex.app.domain.AccountTransactions;
import ru.neoflex.app.repository.AccountTransactionsRepository;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping(path = "transactions")
public class AccountTransactionsController {

    @Autowired
    private AccountTransactionsRepository accountTransactionsRepository;

    @PostMapping
    public AccountTransactions add(@RequestBody AccountTransactions accountTransactions) {
        //todo: valid
        return accountTransactionsRepository.save(accountTransactions);
    }

    @GetMapping
    public List<AccountTransactions> find(@RequestParam Long idUser) {
        return accountTransactionsRepository.findAll().stream().filter(a -> a.getTUser().getId().equals(idUser)).collect(Collectors.toList());
    }

}
