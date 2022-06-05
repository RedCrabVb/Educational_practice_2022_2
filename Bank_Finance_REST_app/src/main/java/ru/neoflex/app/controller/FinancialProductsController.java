package ru.neoflex.app.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import ru.neoflex.app.domain.FinancialProducts;
import ru.neoflex.app.domain.StatusFinancialProducts;
import ru.neoflex.app.repository.FinancialProductsRepository;
import ru.neoflex.app.repository.StatusFinancialProductsRepository;

import java.util.List;
import java.util.stream.Collectors;

@RestController
public class FinancialProductsController {
    @Autowired
    private FinancialProductsRepository financialProductsRepository;

    @Autowired
    private StatusFinancialProductsRepository statusFinancialProductsRepository;

    @GetMapping
    public List<FinancialProducts> get() {
        return financialProductsRepository.findAll();
    }

    @GetMapping
    public List<StatusFinancialProducts> getStatusProducts(@RequestParam Long idUser) {
        return statusFinancialProductsRepository.findAll().stream().filter(a -> a.getUser().getId().equals(idUser)).collect(Collectors.toList());
    }

    @PostMapping
    public StatusFinancialProducts openProduct(StatusFinancialProducts statusFinancialProducts) {
        //todo: valid
        return statusFinancialProductsRepository.save(statusFinancialProducts);
    }
}
