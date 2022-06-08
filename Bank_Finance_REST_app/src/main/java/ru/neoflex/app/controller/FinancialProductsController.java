package ru.neoflex.app.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.web.bind.annotation.*;
import ru.neoflex.app.domain.FinancialProducts;
import ru.neoflex.app.domain.StatusFinancialProducts;
import ru.neoflex.app.repository.FinancialProductsRepository;
import ru.neoflex.app.repository.StatusFinancialProductsRepository;
import ru.neoflex.app.repository.UserRepository;
import ru.neoflex.app.service.UserService;

import java.security.Principal;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("financial_product")
public class FinancialProductsController {
    @Autowired
    private FinancialProductsRepository financialProductsRepository;

    @Autowired
    private StatusFinancialProductsRepository statusFinancialProductsRepository;

    @Autowired
    private UserService userService;

    @GetMapping
    public List<FinancialProducts> get() {
        return financialProductsRepository.findAll();
    }

    @GetMapping(path = "status")
    public List<StatusFinancialProducts> getStatusProducts(Principal principal) {
        var user = userService.findUserByLogin(principal.getName());
        return statusFinancialProductsRepository.findAll().stream().filter(a -> a.getTUser().equals(user)).collect(Collectors.toList());
    }

    @PostMapping
    public StatusFinancialProducts openProduct(@RequestBody StatusFinancialProducts statusFinancialProducts, Principal principal) {
        var user = userService.findUserByLogin(principal.getName());
        statusFinancialProducts.setTUser(user);
        statusFinancialProducts.setFinancialProducts(
                financialProductsRepository.findById(statusFinancialProducts.getFinancialProductsId()).get()
        );
        StatusFinancialProducts result = statusFinancialProductsRepository.save(statusFinancialProducts);
        return result;
    }
}
